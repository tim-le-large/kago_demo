package com.example.backend.config;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;

/**
 * Loads .env files for local development.
 *
 * Supports:
 * - .env in repo root
 * - backend/.env
 *
 * Values are only applied when not already present via env vars, JVM props, or other config.
 */
public class DotenvEnvironmentPostProcessor implements EnvironmentPostProcessor {

	@Override
	public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
		Map<String, Object> props = new LinkedHashMap<>();

		for (Path p : candidateFiles()) {
			loadInto(props, p);
		}

		if (props.isEmpty()) {
			return;
		}

		MutablePropertySources sources = environment.getPropertySources();
		// Low precedence: only fill gaps. Existing env/JVM/config should win.
		sources.addLast(new MapPropertySource("dotenv", props));
	}

	private static List<Path> candidateFiles() {
		Path cwd = Path.of("").toAbsolutePath().normalize();
		return List.of(
				cwd.resolve(".env"),
				cwd.resolve("backend").resolve(".env"));
	}

	private static void loadInto(Map<String, Object> out, Path file) {
		if (!Files.exists(file) || !Files.isRegularFile(file)) {
			return;
		}
		try {
			for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
				Entry e = parseLine(line);
				if (e == null) {
					continue;
				}
				// Only set if not already set by higher-priority sources.
				out.putIfAbsent(e.key(), e.value());
			}
		}
		catch (IOException ignored) {
			// If .env is unreadable, just skip (don't break startup).
		}
	}

	private static Entry parseLine(String raw) {
		if (raw == null) {
			return null;
		}
		String line = raw.trim();
		if (line.isEmpty() || line.startsWith("#")) {
			return null;
		}
		if (line.startsWith("export ")) {
			line = line.substring("export ".length()).trim();
		}
		int idx = line.indexOf('=');
		if (idx <= 0) {
			return null;
		}
		String key = line.substring(0, idx).trim();
		String value = line.substring(idx + 1).trim();
		if (key.isEmpty()) {
			return null;
		}
		value = stripQuotes(value);
		return new Entry(key, value);
	}

	private static String stripQuotes(String s) {
		if (s == null) {
			return "";
		}
		if ((s.startsWith("\"") && s.endsWith("\"")) || (s.startsWith("'") && s.endsWith("'"))) {
			return s.substring(1, s.length() - 1);
		}
		return s;
	}

	private record Entry(String key, String value) {
	}
}

