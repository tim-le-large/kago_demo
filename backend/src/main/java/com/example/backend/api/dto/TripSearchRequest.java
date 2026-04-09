package com.example.backend.api.dto;

import java.time.Instant;

import jakarta.validation.constraints.NotBlank;

public record TripSearchRequest(
		@NotBlank String originRef,
		@NotBlank String destRef,
		Instant departureTime
) {
}
