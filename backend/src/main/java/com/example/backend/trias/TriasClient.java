package com.example.backend.trias;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.example.backend.api.dto.DepartureDto;
import com.example.backend.api.dto.JourneyDto;
import com.example.backend.api.dto.LocationDto;
import com.example.backend.config.TriasProperties;

@Service
public class TriasClient {

	private static final Logger log = LoggerFactory.getLogger(TriasClient.class);

	private final HttpClient httpClient;
	private final TriasProperties triasProperties;
	private final TriasSoapRequestBuilder requestBuilder;
	private final TriasResponseParser responseParser;

	public TriasClient(
			TriasProperties triasProperties,
			TriasSoapRequestBuilder requestBuilder,
			TriasResponseParser responseParser) {
		this.triasProperties = triasProperties;
		this.requestBuilder = requestBuilder;
		this.responseParser = responseParser;
		this.httpClient = HttpClient.newBuilder()
				.connectTimeout(triasProperties.getConnectTimeout())
				.version(HttpClient.Version.HTTP_1_1)
				.build();
	}

	public List<JourneyDto> searchTrips(String originRef, String destRef, Instant departureTime) {
		Instant when = departureTime != null ? departureTime : Instant.now();
		String xmlBody = requestBuilder.buildTripRequest(originRef, destRef, when);
		dump("trip", xmlBody);
		log.debug("TRIAS TripRequest -> {} (originRef={}, destRef={})",
				triasProperties.getEndpoint(), originRef, destRef);
		String xml = postToTrias(xmlBody);
		return xml == null ? List.of() : responseParser.parse(xml);
	}

	public List<LocationDto> searchLocations(String query, int numberOfResults) {
		String xmlBody = requestBuilder.buildLocationInformationRequest(query, numberOfResults);
		dump("location", xmlBody);
		log.debug("TRIAS LocationInformationRequest -> {} (q={}, limit={})",
				triasProperties.getEndpoint(), query, numberOfResults);
		String xml = postToTrias(xmlBody);
		return xml == null ? List.of() : responseParser.parseLocations(xml);
	}

	public List<DepartureDto> searchDepartures(String stopRef, Instant when, int numberOfResults) {
		Instant t = when != null ? when : Instant.now();
		String xmlBody = requestBuilder.buildStopEventRequest(stopRef, t, numberOfResults);
		dump("stop-event", xmlBody);
		log.debug("TRIAS StopEventRequest -> {} (stopRef={}, limit={})",
				triasProperties.getEndpoint(), stopRef, numberOfResults);
		String xml = postToTrias(xmlBody);
		return xml == null ? List.of() : responseParser.parseDepartures(xml);
	}

	private String postToTrias(String xmlBody) {
		try {
			URI uri = URI.create(triasProperties.getEndpoint());
			byte[] bodyBytes = xmlBody.getBytes(StandardCharsets.UTF_8);
			HttpRequest request = HttpRequest.newBuilder(uri)
					.timeout(triasProperties.getReadTimeout())
					.header("Content-Type", "application/xml; charset=utf-8")
					.header("Accept", "*/*")
					.POST(HttpRequest.BodyPublishers.ofByteArray(bodyBytes))
					.build();

			String masked = xmlBody.replace(triasProperties.getRequestorRef(), "****");
			log.debug("TRIAS request ({} bytes) headers={}\n{}", bodyBytes.length, request.headers().map(), masked);

			HttpResponse<String> response = httpClient.send(request,
					HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

			log.debug("TRIAS response status={}, body={}", response.statusCode(), truncate(response.body(), 500));

			if (response.statusCode() >= 400) {
				throw new TriasException(
						"TRIAS-HTTP " + response.statusCode() + ": " + truncate(response.body(), 400));
			}
			String body = response.body();
			if (body == null || body.isBlank()) {
				log.warn("TRIAS returned HTTP {} with empty body — access may not be activated yet.", response.statusCode());
				return null;
			}
			return body;
		}
		catch (TriasException e) {
			throw e;
		}
		catch (IOException e) {
			throw new TriasException("TRIAS-Verbindungsfehler: " + e.getMessage(), e);
		}
		catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			throw new TriasException("TRIAS-Request unterbrochen.", e);
		}
	}

	private void dump(String kind, String xmlBody) {
		if (!triasProperties.isDumpRequests()) {
			return;
		}
		try {
			String masked = xmlBody.replace(triasProperties.getRequestorRef(), "****");
			Path p = Path.of("/tmp", "trias-" + kind + "-request.xml");
			Files.writeString(p, masked, StandardCharsets.UTF_8);
			log.warn("TRIAS request dumped to {}", p);
		}
		catch (Exception e) {
			log.warn("Failed to dump TRIAS request", e);
		}
	}

	private static String truncate(String s, int max) {
		if (s.length() <= max) {
			return s;
		}
		return s.substring(0, max) + "…";
	}
}
