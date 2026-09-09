import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type NearbyType = "hospital" | "pharmacy" | "all";

interface NearbyRequest {
  type?: NearbyType;
  latitude?: number;
  longitude?: number;
}

interface KakaoDocument {
  place_name?: string;
  distance?: string;
  road_address_name?: string;
  address_name?: string;
  phone?: string;
  y?: string;
  x?: string;
  place_url?: string;
}

interface PlaceResult {
  name: string;
  type: "hospital" | "pharmacy";
  distanceMeters: number;
  address: string;
  phone: string;
  latitude: number;
  longitude: number;
  placeUrl: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as NearbyRequest;
    const { type = "all", latitude, longitude } = body;

    if (typeof latitude !== "number" || typeof longitude !== "number") {
      return json({ error: "Invalid request" }, 400);
    }

    const apiKey = Deno.env.get("KAKAO_REST_API_KEY")?.trim();
    if (!apiKey) {
      console.error("nearby: KAKAO_REST_API_KEY secret is missing");
      return json({ error: "Server configuration error" }, 500);
    }

    const types: Array<"hospital" | "pharmacy"> =
      type === "all" ? ["hospital", "pharmacy"] : type === "hospital" || type === "pharmacy"
      ? [type]
      : [];

    if (types.length === 0) {
      return json({ error: "Invalid request" }, 400);
    }

    const results = await Promise.all(
      types.map((t) => fetchCategory(apiKey, t, latitude, longitude)),
    );

    const places = results.flat();
    return json({ places }, 200);
  } catch (err) {
    console.error("nearby: internal error", err);
    const message = err instanceof Error ? err.message : "";
    if (message.includes("Kakao API error")) {
      return json({ error: "Kakao API error" }, 502);
    }
    return json({ error: "Internal error" }, 500);
  }
});

async function fetchCategory(
  apiKey: string,
  type: "hospital" | "pharmacy",
  latitude: number,
  longitude: number,
): Promise<PlaceResult[]> {
  const category = type === "hospital" ? "HP8" : "PM9";
  const url = new URL("https://dapi.kakao.com/v2/local/search/category.json");
  url.searchParams.set("category_group_code", category);
  url.searchParams.set("x", String(longitude));
  url.searchParams.set("y", String(latitude));
  url.searchParams.set("radius", "3000");
  url.searchParams.set("sort", "distance");
  url.searchParams.set("size", "5");

  const kakaoRes = await fetch(url.toString(), {
    headers: { Authorization: `KakaoAK ${apiKey}` },
  });

  if (!kakaoRes.ok) {
    const errorBody = await kakaoRes.text();
    console.error(
      `nearby: Kakao API failed type=${type} status=${kakaoRes.status} body=${errorBody}`,
    );
    throw new Error(`Kakao API error: ${kakaoRes.status}`);
  }

  const kakaoData = await kakaoRes.json();
  const documents = (kakaoData.documents ?? []) as KakaoDocument[];

  return documents.slice(0, 5).map((doc) => ({
    name: doc.place_name ?? "",
    type,
    distanceMeters: parseInt(doc.distance ?? "0", 10) || 0,
    address: doc.road_address_name || doc.address_name || "",
    phone: doc.phone?.trim() || "",
    latitude: parseFloat(doc.y ?? "0") || 0,
    longitude: parseFloat(doc.x ?? "0") || 0,
    placeUrl: doc.place_url ?? "",
  }));
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
