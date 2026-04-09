package com.example.backend.api.dto;

public record LegDto(
		String line,
		String departureStop,
		String arrivalStop,
		String departureTime,
		String arrivalTime
) {
}
