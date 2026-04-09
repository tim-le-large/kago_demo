package com.example.backend.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "trias")
public class TriasProperties {

	private String endpoint = "";
	private String requestorRef = "";
	private Duration connectTimeout = Duration.ofSeconds(10);
	private Duration readTimeout = Duration.ofSeconds(30);
	private boolean dumpRequests = false;

	public String getEndpoint() {
		return endpoint;
	}

	public void setEndpoint(String endpoint) {
		this.endpoint = endpoint;
	}

	public String getRequestorRef() {
		return requestorRef;
	}

	public void setRequestorRef(String requestorRef) {
		this.requestorRef = requestorRef;
	}

	public Duration getConnectTimeout() {
		return connectTimeout;
	}

	public void setConnectTimeout(Duration connectTimeout) {
		this.connectTimeout = connectTimeout;
	}

	public Duration getReadTimeout() {
		return readTimeout;
	}

	public void setReadTimeout(Duration readTimeout) {
		this.readTimeout = readTimeout;
	}

	public boolean isDumpRequests() {
		return dumpRequests;
	}

	public void setDumpRequests(boolean dumpRequests) {
		this.dumpRequests = dumpRequests;
	}
}
