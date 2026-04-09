package com.example.backend.trias;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import com.example.backend.api.dto.LocationDto;

import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
class TriasClientLocationMockServerTest {

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
	void searchLocationsParsesLocationResult() throws IOException {
		String xml = new String(
				new ClassPathResource("trias/location-response-mock.xml").getInputStream().readAllBytes(),
				StandardCharsets.UTF_8);
		MOCK_SERVER.enqueue(new MockResponse()
				.setResponseCode(200)
				.setHeader("Content-Type", "application/xml; charset=utf-8")
				.setBody(xml));

		List<LocationDto> locations = triasClient.searchLocations("tulla", 10);

		assertThat(locations).extracting(LocationDto::id).contains("de:08212:7", "de:08212:89");
	}
}

