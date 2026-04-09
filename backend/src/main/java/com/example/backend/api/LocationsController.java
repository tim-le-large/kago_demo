package com.example.backend.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.api.dto.LocationDto;
import com.example.backend.trias.TriasClient;

import jakarta.validation.constraints.NotBlank;

@RestController
@RequestMapping("/api/v1")
public class LocationsController {

	private final TriasClient triasClient;

	public LocationsController(TriasClient triasClient) {
		this.triasClient = triasClient;
	}

	@GetMapping("/locations")
	public ResponseEntity<List<LocationDto>> locations(
			@RequestParam("q") @NotBlank String query,
			@RequestParam(name = "limit", defaultValue = "10") int limit) {
		return ResponseEntity.ok(triasClient.searchLocations(query, limit));
	}
}

