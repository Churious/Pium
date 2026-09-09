import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const API_BASE = "https://apis.data.go.kr/B552474/SenuriService";

type SeniorJobsAction = "list" | "detail";

interface SeniorJobsRequest {
  action?: SeniorJobsAction;
  pageNo?: number;
  numOfRows?: number;
  search?: string;
  emplymShp?: string;
  workPlcNm?: string;
  jobId?: string;
}

interface SeniorJobJson {
  jobId: string;
  title: string;
  acceptanceStatus: string;
  acceptanceStartDate: string;
  acceptanceEndDate: string;
  workRegion: string;
  workAddress: string;
  employmentType: string;
  jobCategory: string;
  acceptanceMethod: string;
  acceptanceAgency: string;
  workDescription: string;
  recruitAge: string;
  recruitCount: string;
  contactName: string;
  contactPhone: string;
  detailUrl: string;
  otherNotes: string;
}

type UpstreamFailureKind = "auth" | "upstream" | "empty";

class UpstreamError extends Error {
  constructor(
    message: string,
    readonly kind: UpstreamFailureKind,
  ) {
    super(message);
    this.name = "UpstreamError";
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as SeniorJobsRequest;
    const action = body.action ?? "list";

    const apiKey = Deno.env.get("SENIOR_JOB_API_KEY")?.trim();
    if (!apiKey) {
      console.error("senior-jobs: SENIOR_JOB_API_KEY secret is missing");
      return json({ error: "Server configuration error", code: "CONFIG" }, 500);
    }

    if (action === "detail") {
      const jobId = body.jobId?.trim();
      if (!jobId) {
        return json({ error: "Invalid request" }, 400);
      }
      const job = await fetchJobDetail(apiKey, jobId);
      if (!job) {
        return json({ error: "Not found" }, 404);
      }
      return json({ job }, 200);
    }

    const pageNo = normalizePage(body.pageNo);
    const numOfRows = normalizePageSize(body.numOfRows);

    const result = await fetchJobListWithFallback(apiKey, {
      pageNo,
      numOfRows,
      search: body.search?.trim(),
      emplymShp: body.emplymShp?.trim(),
      workPlcNm: body.workPlcNm?.trim(),
    });

    return json(result, 200);
  } catch (err) {
    console.error("senior-jobs: internal error", err);
    if (err instanceof UpstreamError) {
      const status = err.kind === "auth" ? 401 : 502;
      return json(
        {
          error: err.kind === "auth"
            ? "Upstream API auth error"
            : "Upstream API error",
          code: err.kind === "auth" ? "AUTH" : "UPSTREAM",
        },
        status,
      );
    }
    return json({ error: "Internal error" }, 500);
  }
});

async function fetchJobListWithFallback(
  apiKey: string,
  params: {
    pageNo: number;
    numOfRows: number;
    search?: string;
    emplymShp?: string;
    workPlcNm?: string;
  },
): Promise<{
  jobs: SeniorJobJson[];
  pageNo: number;
  numOfRows: number;
  totalCount: number;
}> {
  const attempts: Array<{
    pageNo: number;
    numOfRows: number;
    search?: string;
    emplymShp?: string;
    workPlcNm?: string;
  }> = [params];

  const hasOptionalFilters = Boolean(
    params.search || params.emplymShp || params.workPlcNm,
  );
  if (hasOptionalFilters) {
    attempts.push({
      pageNo: params.pageNo,
      numOfRows: params.numOfRows,
      workPlcNm: params.workPlcNm,
      emplymShp: params.emplymShp,
    });
    attempts.push({
      pageNo: params.pageNo,
      numOfRows: params.numOfRows,
      workPlcNm: params.workPlcNm,
    });
    attempts.push({
      pageNo: params.pageNo,
      numOfRows: params.numOfRows,
    });
  }

  let lastAuthError: UpstreamError | null = null;

  for (const attempt of attempts) {
    try {
      return await fetchJobList(apiKey, attempt);
    } catch (err) {
      if (err instanceof UpstreamError && err.kind === "auth") {
        lastAuthError = err;
        break;
      }
      console.error("senior-jobs: list attempt failed", attempt, err);
    }
  }

  if (lastAuthError) throw lastAuthError;
  throw new UpstreamError("Upstream API error", "upstream");
}

async function fetchJobList(
  apiKey: string,
  params: {
    pageNo: number;
    numOfRows: number;
    search?: string;
    emplymShp?: string;
    workPlcNm?: string;
  },
): Promise<{
  jobs: SeniorJobJson[];
  pageNo: number;
  numOfRows: number;
  totalCount: number;
}> {
  const xml = await fetchSenuriXml(apiKey, "/getJobList", {
    pageNo: String(params.pageNo),
    numOfRows: String(params.numOfRows),
    search: params.search,
    emplymShp: params.emplymShp,
    workPlcNm: params.workPlcNm,
  });
  assertApiSuccess(xml);

  const header = parseHeader(xml);
  const items = parseItems(xml);

  const jobs = items.map(mapListItemToJob);

  return {
    jobs,
    pageNo: parseInt(header.pageNo || String(params.pageNo), 10) || params.pageNo,
    numOfRows: parseInt(header.numOfRows || String(params.numOfRows), 10) ||
      params.numOfRows,
    totalCount: parseInt(header.totalCount || "0", 10) || jobs.length,
  };
}

async function fetchJobDetail(
  apiKey: string,
  jobId: string,
): Promise<SeniorJobJson | null> {
  const xml = await fetchSenuriXml(apiKey, "/getJobInfo", { id: jobId });
  assertApiSuccess(xml);

  const items = parseItems(xml);
  if (items.length === 0) {
    const single = parseSingleItemFields(xml);
    if (!single.jobId && !single.wantedTitle && !single.recrtTitle) {
      return null;
    }
    return mapDetailItemToJob(single);
  }

  return mapDetailItemToJob(items[0]);
}

function serviceKeyVariants(apiKey: string): string[] {
  const trimmed = apiKey.trim();
  const variants = new Set<string>([trimmed]);

  try {
    variants.add(decodeURIComponent(trimmed));
  } catch {
    // ignore decode errors
  }

  for (const key of [...variants]) {
    try {
      variants.add(encodeURIComponent(key));
    } catch {
      // ignore encode errors
    }
  }

  return [...variants];
}

function buildSenuriUrl(
  path: string,
  serviceKey: string,
  params: Record<string, string | undefined>,
): string {
  const base = `${API_BASE}${path}`;
  const isPreEncoded = /%[0-9A-Fa-f]{2}/.test(serviceKey);

  // 인코딩 키는 그대로 붙이고, 디코딩 키는 searchParams로 인코딩합니다.
  if (isPreEncoded) {
    const parts = [`serviceKey=${serviceKey}`];
    for (const [key, value] of Object.entries(params)) {
      if (value) parts.push(`${key}=${encodeURIComponent(value)}`);
    }
    return `${base}?${parts.join("&")}`;
  }

  const url = new URL(base);
  url.searchParams.set("serviceKey", serviceKey);
  for (const [key, value] of Object.entries(params)) {
    if (value) url.searchParams.set(key, value);
  }
  return url.toString();
}

async function fetchSenuriXml(
  apiKey: string,
  path: string,
  params: Record<string, string | undefined>,
): Promise<string> {
  const variants = serviceKeyVariants(apiKey);
  let lastError: UpstreamError | null = null;

  for (const key of variants) {
    const url = buildSenuriUrl(path, key, params);
    try {
      return await fetchXml(url);
    } catch (err) {
      if (err instanceof UpstreamError) {
        lastError = err;
        if (err.kind === "auth") {
          continue;
        }
      }
      throw err;
    }
  }

  throw lastError ?? new UpstreamError("Upstream API auth error", "auth");
}

async function fetchXml(url: string): Promise<string> {
  const res = await fetch(url, {
    headers: { Accept: "application/xml" },
  });
  if (!res.ok) {
    console.error(`senior-jobs: upstream status=${res.status}`);
    throw new UpstreamError(`Upstream HTTP ${res.status}`, "upstream");
  }
  const text = await res.text();
  if (!text.trim()) {
    throw new UpstreamError("Upstream empty response", "empty");
  }
  if (text.includes("OpenAPI_ServiceResponse")) {
    const errMsg = extractTag(text, "returnAuthMsg") ||
      extractTag(text, "errMsg") ||
      "Auth error";
    console.error(`senior-jobs: auth error ${errMsg}`);
    throw new UpstreamError(`Upstream API auth error: ${errMsg}`, "auth");
  }
  return text;
}

function assertApiSuccess(xml: string): void {
  const resultCode = extractTag(xml, "resultCode");
  if (!resultCode) return;
  const normalized = resultCode.trim();
  if (normalized === "00" || normalized === "0000" || normalized === "0") {
    return;
  }
  const resultMsg = extractTag(xml, "resultMsg");
  console.error(`senior-jobs: api resultCode=${normalized} msg=${resultMsg}`);
  if (normalized === "03") {
    // NODATA — 빈 목록으로 처리
    return;
  }
  if (normalized === "10" || normalized === "11" || normalized === "22" ||
    normalized === "30") {
    throw new UpstreamError(
      `Upstream API auth error: ${resultMsg || normalized}`,
      "auth",
    );
  }
  throw new UpstreamError(
    `Upstream API error: ${normalized}`,
    "upstream",
  );
}

function parseHeader(xml: string): Record<string, string> {
  const bodyBlock = extractBlock(xml, "body") ?? xml;
  return {
    pageNo: extractTag(bodyBlock, "pageNo"),
    numOfRows: extractTag(bodyBlock, "numOfRows"),
    totalCount: extractTag(bodyBlock, "totalCount"),
  };
}

function parseItems(xml: string): Record<string, string>[] {
  const itemsBlock = extractBlock(xml, "items");
  if (!itemsBlock) {
    return [];
  }
  const items: Record<string, string>[] = [];
  const itemRegex = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
  let match: RegExpExecArray | null;
  while ((match = itemRegex.exec(itemsBlock)) !== null) {
    items.push(parseSingleItemFields(match[1]));
  }
  return items;
}

function parseSingleItemFields(block: string): Record<string, string> {
  const fields: Record<string, string> = {};
  const tagRegex = /<([A-Za-z0-9_]+)>([\s\S]*?)<\/\1>/g;
  let match: RegExpExecArray | null;
  while ((match = tagRegex.exec(block)) !== null) {
    fields[match[1]] = decodeXml(match[2].trim());
  }
  return fields;
}

function mapListItemToJob(item: Record<string, string>): SeniorJobJson {
  return {
    jobId: item.jobId ?? "",
    title: item.recrtTitle ?? "",
    acceptanceStatus: item.deadline ?? "",
    acceptanceStartDate: formatApiDate(item.frDd),
    acceptanceEndDate: formatApiDate(item.toDd),
    workRegion: item.workPlcNm ?? "",
    workAddress: "",
    employmentType: item.emplymShpNm ?? "",
    jobCategory: item.jobclsNm ?? "",
    acceptanceMethod: item.acptMthd ?? "",
    acceptanceAgency: item.oranNm || item.stmNm || "",
    workDescription: item.jobclsNm ?? "",
    recruitAge: "",
    recruitCount: "",
    contactName: "",
    contactPhone: "",
    detailUrl: "",
    otherNotes: "",
  };
}

function mapDetailItemToJob(item: Record<string, string>): SeniorJobJson {
  const agePart = [item.age, item.ageLim].filter(Boolean).join(" ");
  return {
    jobId: item.jobId ?? item.wantedAuthNo ?? "",
    title: item.wantedTitle ?? item.recrtTitle ?? "",
    acceptanceStatus: item.deadline ?? "",
    acceptanceStartDate: formatApiDate(item.frAcptDd ?? item.frDd),
    acceptanceEndDate: formatApiDate(item.toAcptDd ?? item.toDd),
    workRegion: item.workPlcNm ?? "",
    workAddress: item.plDetAddr ?? "",
    employmentType: item.emplymShpNm ?? "",
    jobCategory: item.jobclsNm ?? "",
    acceptanceMethod: item.acptMthd ?? item.acptMthdCd ?? "",
    acceptanceAgency: item.plbizNm ?? item.oranNm ?? item.stmNm ?? "",
    workDescription: item.detCnts ?? "",
    recruitAge: agePart.trim(),
    recruitCount: item.clltPrnnum ?? "",
    contactName: item.clerk ?? item.repr ?? "",
    contactPhone: item.clerkContt ?? "",
    detailUrl: item.homepage ?? "",
    otherNotes: item.etcItm ?? "",
  };
}

function formatApiDate(raw?: string): string {
  if (!raw) return "";
  const digits = raw.replace(/\D/g, "");
  if (digits.length === 8) {
    return `${digits.slice(0, 4)}.${digits.slice(4, 6)}.${digits.slice(6, 8)}`;
  }
  return raw;
}

function extractBlock(xml: string, tag: string): string | null {
  const re = new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i");
  const m = xml.match(re);
  return m ? m[1] : null;
}

function extractTag(xml: string, tag: string): string {
  const re = new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i");
  const m = xml.match(re);
  return m ? decodeXml(m[1].trim()) : "";
}

function decodeXml(value: string): string {
  return value
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

function normalizePage(value?: number): number {
  if (typeof value !== "number" || value < 1) return 1;
  return Math.floor(value);
}

function normalizePageSize(value?: number): number {
  if (typeof value !== "number" || value < 1) return 10;
  return Math.min(Math.floor(value), 50);
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
