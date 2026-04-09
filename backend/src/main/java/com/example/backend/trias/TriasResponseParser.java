package com.example.backend.trias;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.example.backend.api.dto.DepartureDto;
import com.example.backend.api.dto.JourneyDto;
import com.example.backend.api.dto.LegDto;
import com.example.backend.api.dto.LocationDto;

@Component
public class TriasResponseParser {

	private static final Set<String> NO_RESULTS_CODES = Set.of(
			"TRIP_NOTRIPFOUND", "LOCATION_NORESULTS", "STOPEVENT_NORESULTS");

	private final DocumentBuilderFactory documentBuilderFactory = DocumentBuilderFactory.newInstance();
	private final XPath xpath = XPathFactory.newInstance().newXPath();

	public TriasResponseParser() {
		documentBuilderFactory.setNamespaceAware(true);
		try {
			documentBuilderFactory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
		}
		catch (ParserConfigurationException ignored) {
		}
		documentBuilderFactory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
		documentBuilderFactory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
	}

	public List<JourneyDto> parse(String soapXml) {
		try {
			Document doc = documentBuilderFactory.newDocumentBuilder()
					.parse(new ByteArrayInputStream(soapXml.getBytes(StandardCharsets.UTF_8)));
			checkFault(doc);
			if (hasNoResultsError(doc)) {
				return List.of();
			}
			checkTriasError(doc);
			return parseTrips(doc);
		}
		catch (SAXException | IOException | ParserConfigurationException | XPathExpressionException e) {
			throw new TriasException("TRIAS-Antwort konnte nicht gelesen werden.", e);
		}
	}

	public List<LocationDto> parseLocations(String xml) {
		try {
			Document doc = documentBuilderFactory.newDocumentBuilder()
					.parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
			checkFault(doc);
			if (hasNoResultsError(doc)) {
				return List.of();
			}
			checkTriasError(doc);
			return parseLocationResults(doc);
		}
		catch (SAXException | IOException | ParserConfigurationException | XPathExpressionException e) {
			throw new TriasException("TRIAS-Antwort konnte nicht gelesen werden.", e);
		}
	}

	public List<DepartureDto> parseDepartures(String xml) {
		try {
			Document doc = documentBuilderFactory.newDocumentBuilder()
					.parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
			checkFault(doc);
			if (hasNoResultsError(doc)) {
				return List.of();
			}
			checkTriasError(doc);
			return parseStopEvents(doc);
		}
		catch (SAXException | IOException | ParserConfigurationException | XPathExpressionException e) {
			throw new TriasException("TRIAS-Antwort konnte nicht gelesen werden.", e);
		}
	}

	// ── Error checking ──────────────────────────────────────────────────

	private void checkFault(Document doc) throws XPathExpressionException {
		NodeList faults = (NodeList) xpath.evaluate("//*[local-name()='Fault']", doc, XPathConstants.NODESET);
		if (faults.getLength() > 0) {
			String reason = rawTextContent(faults.item(0));
			throw new TriasException("SOAP-Fault: " + truncate(reason, 500));
		}
	}

	/**
	 * Returns true if the response only contains "no results" errors (not real failures).
	 */
	private boolean hasNoResultsError(Document doc) throws XPathExpressionException {
		NodeList errors = (NodeList) xpath.evaluate("//*[local-name()='ErrorMessage']", doc, XPathConstants.NODESET);
		if (errors.getLength() == 0) {
			return false;
		}
		for (int i = 0; i < errors.getLength(); i++) {
			if (errors.item(i) instanceof Element el) {
				String text = triasText(el, "Text");
				if (text != null && NO_RESULTS_CODES.stream().anyMatch(text::contains)) {
					continue;
				}
				return false;
			}
		}
		return true;
	}

	private void checkTriasError(Document doc) throws XPathExpressionException {
		NodeList errors = (NodeList) xpath.evaluate("//*[local-name()='ErrorMessage']", doc, XPathConstants.NODESET);
		if (errors.getLength() > 0) {
			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < errors.getLength(); i++) {
				if (i > 0) {
					sb.append("; ");
				}
				sb.append(rawTextContent(errors.item(i)));
			}
			throw new TriasException("TRIAS-Fehler: " + sb);
		}
	}

	// ── Trip parsing ────────────────────────────────────────────────────

	private List<JourneyDto> parseTrips(Document doc) throws XPathExpressionException {
		NodeList trips = (NodeList) xpath.evaluate(
				"//*[local-name()='TripResult']/*[local-name()='Trip']",
				doc,
				XPathConstants.NODESET);
		List<JourneyDto> out = new ArrayList<>();
		for (int i = 0; i < trips.getLength(); i++) {
			Node n = trips.item(i);
			if (n instanceof Element tripEl) {
				out.add(parseTrip(tripEl));
			}
		}
		return out;
	}

	private JourneyDto parseTrip(Element trip) {
		List<LegDto> legs = new ArrayList<>();
		NodeList children = trip.getChildNodes();
		for (int i = 0; i < children.getLength(); i++) {
			Node n = children.item(i);
			if (n instanceof Element legEl && "TripLeg".equals(legEl.getLocalName())) {
				LegDto leg = parseLeg(legEl);
				if (leg != null) {
					legs.add(leg);
				}
			}
		}

		String dep = legs.isEmpty() ? null : legs.get(0).departureTime();
		String arr = legs.isEmpty() ? null : legs.get(legs.size() - 1).arrivalTime();
		Integer durationMinutes = parseDurationMinutes(firstChildTextByLocalName(trip, "Duration"));
		if (durationMinutes == null && dep != null && arr != null) {
			try {
				ZonedDateTime d = ZonedDateTime.parse(dep);
				ZonedDateTime a = ZonedDateTime.parse(arr);
				durationMinutes = (int) Duration.between(d.toInstant(), a.toInstant()).toMinutes();
			}
			catch (Exception ignored) {
			}
		}
		int transfers = (int) legs.stream().filter(l -> l.line() != null).count();
		transfers = Math.max(0, transfers - 1);
		return new JourneyDto(dep, arr, durationMinutes, transfers, legs);
	}

	private LegDto parseLeg(Element tripLeg) {
		Element timedLeg = firstChildElementByLocalName(tripLeg, "TimedLeg");
		if (timedLeg != null) {
			return parseTimedLeg(timedLeg);
		}
		Element continuousLeg = firstChildElementByLocalName(tripLeg, "ContinuousLeg");
		if (continuousLeg != null) {
			return parseContinuousLeg(continuousLeg);
		}
		return null;
	}

	private LegDto parseTimedLeg(Element timedLeg) {
		Element board = firstChildElementByLocalName(timedLeg, "LegBoard");
		Element alight = firstChildElementByLocalName(timedLeg, "LegAlight");

		String depStop = board == null ? null : triasText(board, "StopPointName");
		String depTime = extractServiceTime(board, "ServiceDeparture");
		String arrStop = alight == null ? null : triasText(alight, "StopPointName");
		String arrTime = extractServiceTime(alight, "ServiceArrival");

		Element service = firstChildElementByLocalName(timedLeg, "Service");
		String line = service == null ? null : triasText(service, "PublishedLineName");
		if (line == null && service != null) {
			line = triasText(service, "LineName");
		}
		return new LegDto(line, depStop, arrStop, depTime, arrTime);
	}

	private LegDto parseContinuousLeg(Element continuousLeg) {
		Element legStart = firstChildElementByLocalName(continuousLeg, "LegStart");
		Element legEnd = firstChildElementByLocalName(continuousLeg, "LegEnd");

		String depStop = legStart == null ? null : triasText(legStart, "LocationName");
		String arrStop = legEnd == null ? null : triasText(legEnd, "LocationName");
		String depTime = firstDescendantTextByLocalName(continuousLeg, "TimeWindowStart");
		String arrTime = firstDescendantTextByLocalName(continuousLeg, "TimeWindowEnd");

		Element service = firstChildElementByLocalName(continuousLeg, "Service");
		String mode = service == null ? null : firstDescendantTextByLocalName(service, "IndividualMode");

		return new LegDto(mode, depStop, arrStop, depTime, arrTime);
	}

	private String extractServiceTime(Element parent, String serviceElementName) {
		if (parent == null) {
			return null;
		}
		Element serviceEl = firstChildElementByLocalName(parent, serviceElementName);
		if (serviceEl == null) {
			return null;
		}
		String estimated = firstChildTextByLocalName(serviceEl, "EstimatedTime");
		if (estimated != null && !estimated.isBlank()) {
			return estimated.trim();
		}
		String timetabled = firstChildTextByLocalName(serviceEl, "TimetabledTime");
		return timetabled == null ? null : timetabled.trim();
	}

	// ── Departure (StopEvent) parsing ───────────────────────────────────

	private List<DepartureDto> parseStopEvents(Document doc) throws XPathExpressionException {
		NodeList events = (NodeList) xpath.evaluate(
				"//*[local-name()='StopEvent']",
				doc,
				XPathConstants.NODESET);
		List<DepartureDto> out = new ArrayList<>();
		for (int i = 0; i < events.getLength(); i++) {
			Node n = events.item(i);
			if (n instanceof Element el) {
				DepartureDto d = parseStopEvent(el);
				if (d != null) {
					out.add(d);
				}
			}
		}
		return out;
	}

	private DepartureDto parseStopEvent(Element stopEvent) {
		Element service = firstDescendantElementByLocalName(stopEvent, "Service");
		String line = service == null ? null : triasText(service, "PublishedLineName");
		if (line == null && service != null) {
			line = triasText(service, "LineName");
		}

		String planned = firstDescendantTextByLocalName(stopEvent, "TimetabledTime");
		if (planned == null) {
			planned = firstDescendantTextByLocalName(stopEvent, "EstimatedTime");
		}

		String dest = service == null ? null : triasText(service, "DestinationText");
		if (dest == null && service != null) {
			dest = triasText(service, "DestinationName");
		}
		if (dest == null) {
			Element journeyDest = firstDescendantElementByLocalName(stopEvent, "JourneyDestination");
			if (journeyDest != null) {
				dest = triasText(journeyDest, "LocationName");
			}
		}

		if (planned == null || planned.isBlank()) {
			return null;
		}
		return new DepartureDto(
				line == null ? "" : line.trim(),
				dest == null ? "" : dest.trim(),
				planned.trim());
	}

	// ── Location parsing ────────────────────────────────────────────────

	private List<LocationDto> parseLocationResults(Document doc) throws XPathExpressionException {
		// KVV TRIAS: LocationInformationResponse > Location (result) > Location (data)
		NodeList results = (NodeList) xpath.evaluate(
				"//*[local-name()='LocationInformationResponse']/*[local-name()='Location']",
				doc,
				XPathConstants.NODESET);
		List<LocationDto> out = new ArrayList<>();
		for (int i = 0; i < results.getLength(); i++) {
			Node n = results.item(i);
			if (n instanceof Element resultEl) {
				Element locationData = firstChildElementByLocalName(resultEl, "Location");
				if (locationData != null) {
					LocationDto dto = parseLocation(locationData);
					if (dto != null) {
						out.add(dto);
					}
				}
			}
		}
		return out;
	}

	private static LocationDto parseLocation(Element location) {
		String name = triasText(location, "LocationName");
		Element stopPoint = firstChildElementByLocalName(location, "StopPoint");
		if (stopPoint != null) {
			String spName = triasText(stopPoint, "StopPointName");
			if (spName != null) {
				String locName = name;
				name = locName != null ? locName + ", " + spName : spName;
			}
		}

		String id = null;
		if (stopPoint != null) {
			id = firstChildTextByLocalName(stopPoint, "StopPointRef");
		}
		if (id == null) {
			id = firstDescendantTextByLocalName(location, "StopPlaceRef");
		}
		if (id == null) {
			id = firstDescendantTextByLocalName(location, "StopPointRef");
		}

		if (id == null || id.isBlank()) {
			return null;
		}
		return new LocationDto(id.trim(), name == null ? null : name.trim());
	}

	// ── TRIAS text helpers ──────────────────────────────────────────────

	/**
	 * Extracts text from a TRIAS element that uses the Text/Language pattern.
	 * Given a parent and a child local name, finds the child element and returns
	 * the content of its "Text" sub-element (or falls back to raw textContent).
	 */
	private static String triasText(Element parent, String childLocalName) {
		Element child = firstDescendantElementByLocalName(parent, childLocalName);
		if (child == null) {
			return null;
		}
		Element textEl = firstChildElementByLocalName(child, "Text");
		if (textEl != null) {
			return textEl.getTextContent() == null ? null : textEl.getTextContent().trim();
		}
		String raw = child.getTextContent();
		return raw == null ? null : raw.trim();
	}

	// ── DOM helpers ─────────────────────────────────────────────────────

	private static Element firstDescendantElementByLocalName(Element root, String localName) {
		NodeList nl = root.getElementsByTagNameNS("*", localName);
		for (int i = 0; i < nl.getLength(); i++) {
			Node n = nl.item(i);
			if (n instanceof Element el && localName.equals(el.getLocalName())) {
				return el;
			}
		}
		return null;
	}

	private static String firstDescendantTextByLocalName(Element root, String localName) {
		Element el = firstDescendantElementByLocalName(root, localName);
		return el == null ? null : rawTextContent(el).trim();
	}

	private static Element firstChildElementByLocalName(Element parent, String localName) {
		NodeList nl = parent.getChildNodes();
		for (int i = 0; i < nl.getLength(); i++) {
			Node n = nl.item(i);
			if (n instanceof Element el && localName.equals(el.getLocalName())) {
				return el;
			}
		}
		return null;
	}

	private static String firstChildTextByLocalName(Element parent, String localName) {
		Element c = firstChildElementByLocalName(parent, localName);
		return c == null ? null : rawTextContent(c).trim();
	}

	private static String rawTextContent(Node node) {
		return node.getTextContent() == null ? "" : node.getTextContent().trim();
	}

	// ── Misc helpers ────────────────────────────────────────────────────

	private static Integer parseDurationMinutes(String isoDuration) {
		if (isoDuration == null || isoDuration.isBlank()) {
			return null;
		}
		String s = isoDuration.trim().toUpperCase(Locale.ROOT);
		if (!s.startsWith("PT")) {
			return null;
		}
		try {
			int hours = 0;
			int minutes = 0;
			int hIdx = s.indexOf('H');
			if (hIdx > 0) {
				hours = Integer.parseInt(s.substring(2, hIdx));
			}
			int mIdx = s.indexOf('M');
			int from = hIdx >= 0 ? hIdx + 1 : 2;
			if (mIdx > from) {
				minutes = Integer.parseInt(s.substring(from, mIdx));
			}
			return hours * 60 + minutes;
		}
		catch (NumberFormatException e) {
			return null;
		}
	}

	private static String truncate(String s, int max) {
		if (s.length() <= max) {
			return s;
		}
		return s.substring(0, max) + "…";
	}
}
