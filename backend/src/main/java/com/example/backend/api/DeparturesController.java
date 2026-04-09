package com.example.backend.api;

import java.time.Instant;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.api.dto.DepartureDto;
import com.example.backend.trias.TriasClient;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

@RestController
@RequestMapping("/api/v1")
@Validated
public class DeparturesController {

	private final TriasClient triasClient;

	public DeparturesController(TriasClient triasClient) {
		this.triasClient = triasClient;
	}

	/**
	 * Abfahrten an einer Haltestelle (TRIAS StopEventRequest).
	 *
	 * @param stopRef Haltestellen-ID (z. B. aus der Location-Suche)
	 * @param when optional; Standard jetzt (UTC)
	 */
	@GetMapping("/departures")
	public ResponseEntity<List<DepartureDto>> departures(
			@RequestParam("stopRef") @NotBlank String stopRef,
			@RequestParam(name = "when", required = false) Instant when,
			@RequestParam(name = "limit", defaultValue = "15") @Min(1) @Max(50) int limit) {
		Instant t = when != null ? when : Instant.now();
		return ResponseEntity.ok(triasClient.searchDepartures(stopRef, t, limit));
	}
}
