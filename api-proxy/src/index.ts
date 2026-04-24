import { XMLParser } from "fast-xml-parser";

type Env = {
  TRIAS_ENDPOINT: string;
  TRIAS_REQUESTOR_REF: string;
};

type TripsBody = {
  originRef: string;
  destRef: string;
  departureTime?: string;
};

const KARLSRUHE_TZ = "Europe/Berlin";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const url = new URL(request.url);

      if (request.method === "OPTIONS") {
        return withCors(new Response(null, { status: 204 }), request);
      }

      if (url.pathname === "/health") {
        return withCors(json({ ok: true }), request);
      }

      if (!url.pathname.startsWith("/api/v1/")) {
        return withCors(json({ error: "not_found" }, 404), request);
      }

      if (request.method === "GET" && url.pathname === "/api/v1/locations") {
        return await handleLocations(url, env, request);
      }
      if (request.method === "GET" && url.pathname === "/api/v1/departures") {
        return await handleDepartures(url, env, request);
      }
      if (request.method === "POST" && url.pathname === "/api/v1/trips") {
        return await handleTrips(request, env);
      }

      return withCors(json({ error: "method_not_allowed" }, 405), request);
    } catch (e) {
      return withCors(json({ error: "internal_error", detail: String(e) }, 500), request);
    }
  },
};

async function handleLocations(url: URL, env: Env, req: Request): Promise<Response> {
  requireRequestorRef(env);
  const q = (url.searchParams.get("q") ?? "").trim();
  if (!q) {
    return withCors(json({ error: "missing_q" }, 400), req);
  }
  const limit = clampInt(url.searchParams.get("limit"), 10, 1, 50);

  const xmlBody = buildLocationInformationRequest(env.TRIAS_REQUESTOR_REF, q, limit);
  const xml = await postToTrias(env, xmlBody);
  const out = parseLocations(xml);
  return withCors(json(out), req);
}

async function handleDepartures(url: URL, env: Env, req: Request): Promise<Response> {
  requireRequestorRef(env);
  const stopRef = (url.searchParams.get("stopRef") ?? "").trim();
  if (!stopRef) {
    return withCors(json({ error: "missing_stopRef" }, 400), req);
  }

  const whenRaw = (url.searchParams.get("when") ?? "").trim();
  const when = whenRaw ? new Date(whenRaw) : new Date();
  if (Number.isNaN(when.getTime())) {
    return withCors(json({ error: "invalid_when" }, 400), req);
  }
  const limit = clampInt(url.searchParams.get("limit"), 15, 1, 50);

  const xmlBody = buildStopEventRequest(env.TRIAS_REQUESTOR_REF, stopRef, when, limit);
  const xml = await postToTrias(env, xmlBody);
  const out = parseDepartures(xml);
  return withCors(json(out), req);
}

async function handleTrips(req: Request, env: Env): Promise<Response> {
  requireRequestorRef(env);
  const body = (await req.json().catch(() => null)) as TripsBody | null;
  if (!body || !body.originRef || !body.destRef) {
    return withCors(json({ error: "invalid_body" }, 400), req);
  }

  const when = body.departureTime ? new Date(body.departureTime) : new Date();
  if (Number.isNaN(when.getTime())) {
    return withCors(json({ error: "invalid_departureTime" }, 400), req);
  }

  const xmlBody = buildTripRequest(env.TRIAS_REQUESTOR_REF, body.originRef, body.destRef, when, 10);
  const xml = await postToTrias(env, xmlBody);
  const journeys = parseTrips(xml);
  return withCors(json({ journeys }), req);
}

function requireRequestorRef(env: Env) {
  const ref = env.TRIAS_REQUESTOR_REF;
  if (!ref || !ref.trim() || ref.trim().toLowerCase() === "changeme") {
    throw new Error("TRIAS_REQUESTOR_REF is not set");
  }
}

async function postToTrias(env: Env, xmlBody: string): Promise<string> {
  const endpoint = env.TRIAS_ENDPOINT || "https://projekte.kvv-efa.de/lelargetrias/trias";
  const resp = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      Accept: "*/*",
    },
    body: xmlBody,
  });

  const text = await resp.text();
  if (resp.status >= 400) {
    throw new Error(`TRIAS HTTP ${resp.status}: ${text.slice(0, 400)}`);
  }
  if (!text || !text.trim()) {
    return "";
  }
  return text;
}

// -------------------- XML building --------------------

function buildTripRequest(
  requestorRefRaw: string,
  originRef: string,
  destRef: string,
  departure: Date,
  numberOfResults: number,
): string {
  const requestorRef = escapeXml(requestorRefRaw);
  const now = formatTriasTime(new Date());
  const dep = formatTriasTime(departure);
  const n = String(clamp(numberOfResults, 1, 50));

  return `<?xml version="1.0" encoding="UTF-8"?>
<Trias version="1.1"
  xmlns="http://www.vdv.de/trias"
  xmlns:siri="http://www.siri.org.uk/siri">
  <ServiceRequest>
    <siri:RequestTimeStamp>${escapeXml(now)}</siri:RequestTimeStamp>
    <siri:RequestorRef>${requestorRef}</siri:RequestorRef>
    <RequestPayload>
      <TripRequest>
        <Origin>
          <LocationRef>
            <StopPlaceRef>${escapeXml(originRef)}</StopPlaceRef>
          </LocationRef>
          <DepArrTime>${escapeXml(dep)}</DepArrTime>
        </Origin>
        <Destination>
          <LocationRef>
            <StopPlaceRef>${escapeXml(destRef)}</StopPlaceRef>
          </LocationRef>
        </Destination>
        <Params>
          <NumberOfResults>${n}</NumberOfResults>
          <IncludeFares>false</IncludeFares>
        </Params>
      </TripRequest>
    </RequestPayload>
  </ServiceRequest>
</Trias>`;
}

function buildLocationInformationRequest(requestorRefRaw: string, query: string, numberOfResults: number): string {
  const requestorRef = escapeXml(requestorRefRaw);
  const now = formatTriasTime(new Date());
  const n = String(clamp(numberOfResults, 1, 50));
  return `<?xml version="1.0" encoding="UTF-8"?>
<Trias version="1.1"
  xmlns="http://www.vdv.de/trias"
  xmlns:siri="http://www.siri.org.uk/siri">
  <ServiceRequest>
    <siri:RequestTimeStamp>${escapeXml(now)}</siri:RequestTimeStamp>
    <siri:RequestorRef>${requestorRef}</siri:RequestorRef>
    <RequestPayload>
      <LocationInformationRequest>
        <InitialInput>
          <LocationName>${escapeXml(query)}</LocationName>
        </InitialInput>
        <Restrictions>
          <Type>stop</Type>
        </Restrictions>
        <Params>
          <NumberOfResults>${n}</NumberOfResults>
        </Params>
      </LocationInformationRequest>
    </RequestPayload>
  </ServiceRequest>
</Trias>`;
}

function buildStopEventRequest(
  requestorRefRaw: string,
  stopRef: string,
  departureOrArrivalTime: Date,
  numberOfResults: number,
): string {
  const requestorRef = escapeXml(requestorRefRaw);
  const now = formatTriasTime(new Date());
  const dep = formatTriasTime(departureOrArrivalTime);
  const n = String(clamp(numberOfResults, 1, 50));
  return `<?xml version="1.0" encoding="UTF-8"?>
<Trias version="1.1"
  xmlns="http://www.vdv.de/trias"
  xmlns:siri="http://www.siri.org.uk/siri">
  <ServiceRequest>
    <siri:RequestTimeStamp>${escapeXml(now)}</siri:RequestTimeStamp>
    <siri:RequestorRef>${requestorRef}</siri:RequestorRef>
    <RequestPayload>
      <StopEventRequest>
        <Location>
          <LocationRef>
            <StopPlaceRef>${escapeXml(stopRef)}</StopPlaceRef>
          </LocationRef>
          <DepArrTime>${escapeXml(dep)}</DepArrTime>
        </Location>
        <Params>
          <NumberOfResults>${n}</NumberOfResults>
        </Params>
      </StopEventRequest>
    </RequestPayload>
  </ServiceRequest>
</Trias>`;
}

function formatTriasTime(date: Date): string {
  const parts = new Intl.DateTimeFormat("sv-SE", {
    timeZone: KARLSRUHE_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).format(date);
  return parts.replace(" ", "T");
}

function escapeXml(raw: string): string {
  return (raw ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

// -------------------- XML parsing --------------------

const NO_RESULTS_CODES = ["TRIP_NOTRIPFOUND", "LOCATION_NORESULTS", "STOPEVENT_NORESULTS"];

function parseTrips(xml: string): unknown[] {
  const root = parseXmlRoot(xml);
  if (!root) return [];
  if (hasNoResultsError(root)) return [];
  checkFault(root);
  checkTriasError(root);

  const tripResults = findAll(root, "TripResult");
  const trips: any[] = [];
  for (const tr of tripResults) {
    trips.push(...findAll(tr, "Trip"));
  }
  return trips.map((t) => parseTrip(t)).filter(Boolean) as unknown[];
}

function parseTrip(trip: any): unknown | null {
  const tripLegs = arrayify(trip?.TripLeg);
  const legs: any[] = [];
  for (const tl of tripLegs) {
    const timedLeg = tl?.TimedLeg ?? null;
    const continuousLeg = tl?.ContinuousLeg ?? null;
    if (timedLeg) {
      const leg = parseTimedLeg(timedLeg);
      if (leg) legs.push(leg);
    } else if (continuousLeg) {
      const leg = parseContinuousLeg(continuousLeg);
      if (leg) legs.push(leg);
    }
  }

  const dep = legs.length ? legs[0].departureTime : null;
  const arr = legs.length ? legs[legs.length - 1].arrivalTime : null;

  const durationIso = text(trip?.Duration);
  let durationMinutes = parseDurationMinutes(durationIso);
  if (durationMinutes == null && dep && arr) {
    const d = Date.parse(dep);
    const a = Date.parse(arr);
    if (!Number.isNaN(d) && !Number.isNaN(a)) {
      durationMinutes = Math.floor((a - d) / 60000);
    }
  }

  let transfers = legs.filter((l) => l.line != null).length;
  transfers = Math.max(0, transfers - 1);

  return { departureTime: dep, arrivalTime: arr, durationMinutes, transfers, legs };
}

function parseTimedLeg(timedLeg: any): any | null {
  const board = timedLeg?.LegBoard ?? null;
  const alight = timedLeg?.LegAlight ?? null;

  const depStop = board ? triasText(board, "StopPointName") : null;
  const depTime = extractServiceTime(board, "ServiceDeparture");
  const arrStop = alight ? triasText(alight, "StopPointName") : null;
  const arrTime = extractServiceTime(alight, "ServiceArrival");

  const service = timedLeg?.Service ?? null;
  let line = service ? triasText(service, "PublishedLineName") : null;
  if (!line && service) line = triasText(service, "LineName");

  return { line, departureStop: depStop, arrivalStop: arrStop, departureTime: depTime, arrivalTime: arrTime };
}

function parseContinuousLeg(continuousLeg: any): any | null {
  const legStart = continuousLeg?.LegStart ?? null;
  const legEnd = continuousLeg?.LegEnd ?? null;

  const depStop = legStart ? triasText(legStart, "LocationName") : null;
  const arrStop = legEnd ? triasText(legEnd, "LocationName") : null;
  const depTime = firstDescendantText(continuousLeg, "TimeWindowStart");
  const arrTime = firstDescendantText(continuousLeg, "TimeWindowEnd");

  const service = continuousLeg?.Service ?? null;
  const mode = service ? firstDescendantText(service, "IndividualMode") : null;

  return { line: mode ?? "walk", departureStop: depStop, arrivalStop: arrStop, departureTime: depTime, arrivalTime: arrTime };
}

function parseLocations(xml: string): unknown[] {
  const root = parseXmlRoot(xml);
  if (!root) return [];
  if (hasNoResultsError(root)) return [];
  checkFault(root);
  checkTriasError(root);

  const responses = findAll(root, "LocationInformationResponse");
  const out: any[] = [];
  for (const r of responses) {
    const resultLocations = arrayify(r?.Location);
    for (const resultEl of resultLocations) {
      const locationData = resultEl?.Location ?? null;
      if (!locationData) continue;
      const dto = parseLocation(locationData);
      if (dto) out.push(dto);
    }
  }
  return out;
}

function parseLocation(location: any): any | null {
  let name = triasText(location, "LocationName");
  const stopPoint = location?.StopPoint ?? null;
  if (stopPoint) {
    const spName = triasText(stopPoint, "StopPointName");
    if (spName) name = name ? `${name}, ${spName}` : spName;
  }

  const id =
    (stopPoint ? text(stopPoint?.StopPointRef) : null) ??
    firstDescendantText(location, "StopPlaceRef") ??
    firstDescendantText(location, "StopPointRef");

  if (!id || !id.trim()) return null;
  return { id: id.trim(), name: name ?? null };
}

function parseDepartures(xml: string): unknown[] {
  const root = parseXmlRoot(xml);
  if (!root) return [];
  if (hasNoResultsError(root)) return [];
  checkFault(root);
  checkTriasError(root);

  const events = findAll(root, "StopEvent");
  const out: any[] = [];
  for (const el of events) {
    const d = parseStopEvent(el);
    if (d) out.push(d);
  }
  out.sort((a, b) => {
    const ta = Date.parse((a as { plannedTime?: string }).plannedTime ?? "");
    const tb = Date.parse((b as { plannedTime?: string }).plannedTime ?? "");
    if (Number.isNaN(ta) && Number.isNaN(tb)) return 0;
    if (Number.isNaN(ta)) return 1;
    if (Number.isNaN(tb)) return -1;
    return ta - tb;
  });
  return out;
}

/** Departure at the requested stop: ThisCall → ServiceDeparture (not Previous/Onward). */
function departureTimeFromThisCall(stopEvent: any): string | null {
  const thisCall = stopEvent?.ThisCall;
  if (!thisCall || typeof thisCall !== "object") return null;
  const atStops = arrayify(thisCall.CallAtStop);
  const atStop = atStops[0];
  if (!atStop) return null;
  const dep = atStop.ServiceDeparture ?? atStop.CallDeparture ?? null;
  if (!dep) return null;
  const est = firstDescendantText(dep, "EstimatedTime");
  if (est?.trim()) return est.trim();
  const tim = firstDescendantText(dep, "TimetabledTime");
  return tim?.trim() ?? null;
}

function parseStopEvent(stopEvent: any): any | null {
  const service = firstDescendant(stopEvent, "Service");
  let line = service ? triasText(service, "PublishedLineName") : null;
  if (!line && service) line = triasText(service, "LineName");

  let planned = departureTimeFromThisCall(stopEvent);
  if (!planned) planned = firstDescendantText(stopEvent, "TimetabledTime");
  if (!planned) planned = firstDescendantText(stopEvent, "EstimatedTime");

  let dest = service ? triasText(service, "DestinationText") : null;
  if (!dest && service) dest = triasText(service, "DestinationName");
  if (!dest) {
    const journeyDest = firstDescendant(stopEvent, "JourneyDestination");
    if (journeyDest) dest = triasText(journeyDest, "LocationName");
  }

  if (!planned || !planned.trim()) return null;
  return { line: (line ?? "").trim(), destination: (dest ?? "").trim(), plannedTime: planned.trim() };
}

function parseXmlRoot(xml: string): any | null {
  if (!xml || !xml.trim()) return null;
  const parser = new XMLParser({
    ignoreAttributes: true,
    removeNSPrefix: true,
    trimValues: true,
    parseTagValue: false,
    parseAttributeValue: false,
    textNodeName: "#text",
  });
  return parser.parse(xml);
}

function checkFault(root: any) {
  const faults = findAll(root, "Fault");
  if (faults.length) throw new Error(`SOAP-Fault: ${truncate(text(faults[0]) ?? "", 500)}`);
}

function hasNoResultsError(root: any): boolean {
  const errors = findAll(root, "ErrorMessage");
  if (!errors.length) return false;
  for (const el of errors) {
    const t = triasText(el, "Text") ?? text(el) ?? "";
    if (NO_RESULTS_CODES.some((c) => t.includes(c))) continue;
    return false;
  }
  return true;
}

function checkTriasError(root: any) {
  const errors = findAll(root, "ErrorMessage");
  if (!errors.length) return;
  const msg = errors.map((e) => (text(e) ?? "").trim()).filter(Boolean).join("; ");
  throw new Error(`TRIAS-Fehler: ${truncate(msg, 800)}`);
}

function triasText(parent: any, childLocalName: string): string | null {
  const child = firstDescendant(parent, childLocalName);
  if (!child) return null;
  const textEl = child?.Text ?? null;
  const t = text(textEl) ?? text(child);
  return t == null ? null : t.trim();
}

function extractServiceTime(parent: any | null, serviceElementName: string): string | null {
  if (!parent) return null;
  const serviceEl = parent?.[serviceElementName] ?? null;
  if (!serviceEl) return null;
  const estimated = text(serviceEl?.EstimatedTime);
  if (estimated && estimated.trim()) return estimated.trim();
  const timetabled = text(serviceEl?.TimetabledTime);
  return timetabled ? timetabled.trim() : null;
}

function arrayify<T>(v: T | T[] | undefined | null): T[] {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}

function text(v: any): string | null {
  if (v == null) return null;
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (typeof v === "object") {
    if (typeof v["#text"] === "string") return v["#text"];
    if (typeof v.Text === "string") return v.Text;
    if (typeof v.Value === "string") return v.Value;
  }
  return null;
}

function firstDescendant(root: any, key: string): any | null {
  if (root == null || typeof root !== "object") return null;
  const stack: any[] = [root];
  while (stack.length) {
    const cur = stack.pop();
    if (cur == null || typeof cur !== "object") continue;
    if (Object.prototype.hasOwnProperty.call(cur, key)) return cur[key];
    for (const v of Object.values(cur)) {
      if (v && typeof v === "object") stack.push(v);
    }
  }
  return null;
}

function firstDescendantText(root: any, key: string): string | null {
  const v = firstDescendant(root, key);
  if (v == null) return null;
  if (Array.isArray(v)) {
    for (const item of v) {
      const t = text(item);
      if (t != null) return t;
    }
    return null;
  }
  return text(v);
}

function findAll(root: any, key: string): any[] {
  const out: any[] = [];
  if (root == null || typeof root !== "object") return out;
  const stack: any[] = [root];
  while (stack.length) {
    const cur = stack.pop();
    if (cur == null || typeof cur !== "object") continue;
    const v = (cur as any)[key];
    if (v != null) out.push(...arrayify(v));
    for (const child of Object.values(cur)) {
      if (child && typeof child === "object") stack.push(child);
    }
  }
  return out;
}

function parseDurationMinutes(isoDuration: string | null): number | null {
  if (!isoDuration) return null;
  const s = isoDuration.trim().toUpperCase();
  if (!s.startsWith("PT")) return null;
  const h = s.match(/(\d+)H/);
  const m = s.match(/(\d+)M/);
  const hours = h ? Number.parseInt(h[1]!, 10) : 0;
  const minutes = m ? Number.parseInt(m[1]!, 10) : 0;
  if (Number.isNaN(hours) || Number.isNaN(minutes)) return null;
  return hours * 60 + minutes;
}

function clampInt(raw: string | null, fallback: number, min: number, max: number): number {
  if (!raw) return fallback;
  const n = Number.parseInt(raw, 10);
  if (Number.isNaN(n)) return fallback;
  return clamp(n, min, max);
}

function clamp(n: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, n));
}

function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max)}…`;
}

// -------------------- HTTP helpers --------------------

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function withCors(resp: Response, req: Request): Response {
  const origin = req.headers.get("Origin") ?? "*";
  const headers = new Headers(resp.headers);
  headers.set("Access-Control-Allow-Origin", origin);
  headers.set("Vary", "Origin");
  headers.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type");
  return new Response(resp.body, { status: resp.status, headers });
}

