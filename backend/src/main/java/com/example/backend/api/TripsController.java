package com.example.backend.api;

import java.time.Instant;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.api.dto.JourneyDto;
import com.example.backend.api.dto.TripSearchRequest;
import com.example.backend.api.dto.TripsResponse;
import com.example.backend.trias.TriasClient;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1")
public class TripsController {

	private final TriasClient triasClient;

	public TripsController(TriasClient triasClient) {
		this.triasClient = triasClient;
	}

	@PostMapping("/trips")
	public ResponseEntity<TripsResponse> trips(@Valid @RequestBody TripSearchRequest request) {
		Instant when = request.departureTime() != null ? request.departureTime() : Instant.now();
		List<JourneyDto> journeys = triasClient.searchTrips(request.originRef(), request.destRef(), when);
		return ResponseEntity.ok(new TripsResponse(journeys));
	}
}
