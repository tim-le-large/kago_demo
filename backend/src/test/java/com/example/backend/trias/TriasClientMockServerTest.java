package com.example.backend.trias;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import com.example.backend.api.dto.DepartureDto;
import com.example.backend.api.dto.JourneyDto;

import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
class TriasClientMockServerTest {

	private static final MockWebServer MOCK_SERVER = new MockWebServer();

	static {
		try {
			MOCK_SERVER.start();
		}
		catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	@AfterAll
	static void tearDown() throws IOException {
		MOCK_SERVER.shutdown();
	}

	@DynamicPropertySource
	static void triasProperties(DynamicPropertyRegistry registry) {
		String raw = MOCK_SERVER.url("/").toString();
		final String base = raw.endsWith("/") ? raw.substring(0, raw.length() - 1) : raw;
		final String endpoint = base + "/lelargetrias/trias";
		registry.add("trias.endpoint", () -> endpoint);
		registry.add("trias.requestor-ref", () -> "test-requestor");
	}

	@Autowired
	TriasClient triasClient;

	@Test
	void searchTripsReturnsParsedJourneys() throws IOException {
		String soapBody = new String(
				new ClassPathResource("trias/trip-response-mock.xml").getInputStream().readAllBytes(),
				StandardCharsets.UTF_8);
		MOCK_SERVER.enqueue(new MockResponse()
				.setResponseCode(200)
				.setHeader("Content-Type", "application/soap+xml; charset=utf-8")
				.setBody(soapBody));

		List<JourneyDto> journeys = triasClient.searchTrips(
				"origin-stop",
				"dest-stop",
				Instant.parse("2026-04-02T12:00:00Z"));

		assertThat(journeys).hasSize(1);
		assertThat(journeys.get(0).legs()).hasSize(1);
		assertThat(journeys.get(0).legs().get(0).line()).isEqualTo("S2");
		assertThat(journeys.get(0).durationMinutes()).isEqualTo(25);
	}

	@Test
	void searchDeparturesReturnsParsedDepartures() throws IOException {
		String soapBody = new String(
				new ClassPathResource("trias/stop-event-response-mock.xml").getInputStream().readAllBytes(),
				StandardCharsets.UTF_8);
		MOCK_SERVER.enqueue(new MockResponse()
				.setResponseCode(200)
				.setHeader("Content-Type", "application/soap+xml; charset=utf-8")
				.setBody(soapBody));

		List<DepartureDto> deps = triasClient.searchDepartures(
				"de:test:stop",
				Instant.parse("2026-04-02T12:00:00Z"),
				10);

		assertThat(deps).hasSize(2);
		assertThat(deps.get(0).line()).isEqualTo("S2");
		assertThat(deps.get(0).destination()).isEqualTo("Rheinstetten");
		assertThat(deps.get(1).line()).isEqualTo("5");
	}
}
