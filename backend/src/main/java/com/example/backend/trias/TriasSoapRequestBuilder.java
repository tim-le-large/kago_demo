package com.example.backend.trias;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;

import com.example.backend.config.TriasProperties;

@Component
public class TriasSoapRequestBuilder {

	private static final ZoneId KARLSRUHE = ZoneId.of("Europe/Berlin");
	// KVV/EFA is picky: avoid fractional seconds
	private static final DateTimeFormatter TRIAS_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

	private final String tripTemplate;
	private final String locationTemplate;
	private final String stopEventTemplate;
	private final TriasProperties triasProperties;

	public TriasSoapRequestBuilder(TriasProperties triasProperties) {
		this.triasProperties = triasProperties;
		try {
			this.tripTemplate = StreamUtils.copyToString(
					new ClassPathResource("trias/trip-request.xml").getInputStream(),
					StandardCharsets.UTF_8);
			this.locationTemplate = StreamUtils.copyToString(
					new ClassPathResource("trias/location-information-request.xml").getInputStream(),
					StandardCharsets.UTF_8);
			this.stopEventTemplate = StreamUtils.copyToString(
					new ClassPathResource("trias/stop-event-request.xml").getInputStream(),
					StandardCharsets.UTF_8);
		}
		catch (IOException e) {
			throw new UncheckedIOException(e);
		}
	}

	public String buildTripRequest(String originRef, String destRef, Instant departure) {
		String requestorRefRaw = triasProperties.getRequestorRef();
		requireRequestorRef(requestorRefRaw);
		String requestorRef = escapeXml(requestorRefRaw);
		LocalDateTime now = LocalDateTime.now(KARLSRUHE).withNano(0);
		LocalDateTime dep = LocalDateTime.ofInstant(departure, KARLSRUHE).withNano(0);
		return tripTemplate
				.replace("{{requestTimestamp}}", escapeXml(TRIAS_TIME.format(now)))
				.replace("{{requestorRef}}", requestorRef)
				.replace("{{originRef}}", escapeXml(originRef))
				.replace("{{destRef}}", escapeXml(destRef))
				.replace("{{depArrTime}}", escapeXml(TRIAS_TIME.format(dep)))
				.replace("{{numberOfResults}}", "10");
	}

	public String buildStopEventRequest(String stopRef, Instant departureOrArrivalTime, int numberOfResults) {
		String requestorRefRaw = triasProperties.getRequestorRef();
		requireRequestorRef(requestorRefRaw);
		String requestorRef = escapeXml(requestorRefRaw);
		LocalDateTime now = LocalDateTime.now(KARLSRUHE).withNano(0);
		LocalDateTime dep = LocalDateTime.ofInstant(departureOrArrivalTime, KARLSRUHE).withNano(0);
		return stopEventTemplate
				.replace("{{requestTimestamp}}", escapeXml(TRIAS_TIME.format(now)))
				.replace("{{requestorRef}}", requestorRef)
				.replace("{{stopRef}}", escapeXml(stopRef))
				.replace("{{depArrTime}}", escapeXml(TRIAS_TIME.format(dep)))
				.replace("{{numberOfResults}}", Integer.toString(Math.max(1, Math.min(numberOfResults, 50))));
	}

	public String buildLocationInformationRequest(String query, int numberOfResults) {
		String requestorRefRaw = triasProperties.getRequestorRef();
		requireRequestorRef(requestorRefRaw);
		String requestorRef = escapeXml(requestorRefRaw);
		LocalDateTime now = LocalDateTime.now(KARLSRUHE).withNano(0);
		return locationTemplate
				.replace("{{requestTimestamp}}", escapeXml(TRIAS_TIME.format(now)))
				.replace("{{requestorRef}}", requestorRef)
				.replace("{{query}}", escapeXml(query))
				.replace("{{numberOfResults}}", Integer.toString(Math.max(1, Math.min(numberOfResults, 50))));
	}

	private static void requireRequestorRef(String requestorRef) {
		if (requestorRef == null || requestorRef.isBlank() || "changeme".equalsIgnoreCase(requestorRef.trim())) {
			throw new TriasException("TRIAS_REQUESTOR_REF ist nicht gesetzt. Bitte in .env eintragen und vor bootRun laden.");
		}
	}

	private static String escapeXml(String raw) {
		if (raw == null) {
			return "";
		}
		return raw
				.replace("&", "&amp;")
				.replace("<", "&lt;")
				.replace(">", "&gt;")
				.replace("\"", "&quot;")
				.replace("'", "&apos;");
	}
}
