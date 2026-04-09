package com.example.backend.api.dto;

public record DepartureDto(
		String line,
		String destination,
		String plannedTime
) {
}
