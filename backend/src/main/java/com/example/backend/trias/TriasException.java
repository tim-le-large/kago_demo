package com.example.backend.trias;

public class TriasException extends RuntimeException {

	public TriasException(String message) {
		super(message);
	}

	public TriasException(String message, Throwable cause) {
		super(message, cause);
	}
}
