package com.example.backend.api.dto;

import java.util.List;

public record JourneyDto(
		String departureTime,
		String arrivalTime,
		Integer durationMinutes,
		int transfers,
		List<LegDto> legs
) {
}
