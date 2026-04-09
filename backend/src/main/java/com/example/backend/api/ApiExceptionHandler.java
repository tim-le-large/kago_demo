package com.example.backend.api;

import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.example.backend.trias.TriasException;

@RestControllerAdvice
public class ApiExceptionHandler {

	@ExceptionHandler(TriasException.class)
	public ResponseEntity<ProblemDetail> trias(TriasException ex) {
		ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_GATEWAY, ex.getMessage());
		pd.setTitle("TRIAS-Fehler");
		return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(pd);
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<ProblemDetail> validation(MethodArgumentNotValidException ex) {
		String detail = ex.getBindingResult().getFieldErrors().stream()
				.map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
				.collect(Collectors.joining("; "));
		ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, detail);
		pd.setTitle("Ungültige Anfrage");
		return ResponseEntity.badRequest().body(pd);
	}
}
