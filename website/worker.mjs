import release from "./release.json" with { type: "json" };

const endpoint = "https://gesxgjsjrdwjpxebzqul.supabase.co/rest/v1/nano_events";
// Public insert-only key, also used by the page-view tracker; never use a service-role key here.
const publishableKey = "sb_publishable_Za8_AYxM2gtYp0aHCuzIlg_bxRsYbUO";
const visitorKey = "nano_md_visitor_id";
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function cookie(request, name) {
  return (request.headers.get("Cookie") || "").split(";")
    .map(part => part.trim()).find(part => part.startsWith(`${name}=`))?.slice(name.length + 1);
}

function referrerHostname(request) {
  try {
    return new URL(request.headers.get("Referer")).hostname.slice(0, 500) || null;
  } catch {
    return null;
  }
}

async function recordDownload(event) {
  let failure = "network_error";
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await new Promise(resolve => setTimeout(resolve, attempt * 250));
    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: { apikey: publishableKey, "Content-Type": "application/json", Prefer: "return=minimal" },
        body: JSON.stringify(event),
        signal: AbortSignal.timeout(3000),
        redirect: "manual",
      });
      await response.body?.cancel();
      // Retrying the same event UUID cannot add a second row if the first response was lost.
      if (response.ok || (attempt > 0 && response.status === 409)) {
        console.log(JSON.stringify({ event: "download_recorded", id: event.id, release: release.tag }));
        return;
      }
      failure = `http_${response.status}`;
      if (response.status !== 408 && response.status !== 429 && response.status < 500) break;
    } catch (error) {
      failure = `${error.name}: ${error.message}`.slice(0, 300);
    }
  }
  console.error(JSON.stringify({ event: "download_recording_failed", id: event.id, release: release.tag, reason: failure }));
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname !== "/download" && url.pathname !== "/download/") return env.ASSETS.fetch(request);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", { status: 405, headers: { Allow: "GET, HEAD", "Cache-Control": "no-store" } });
    }

    const asset = await env.ASSETS.fetch(new Request(new URL("/download", url), { method: request.method }));
    if (!asset.ok) {
      await asset.body?.cancel();
      console.error(JSON.stringify({ event: "download_asset_unavailable", status: asset.status, release: release.tag }));
      return new Response("Download temporarily unavailable", { status: 503, headers: { "Cache-Control": "no-store" } });
    }
    const headers = new Headers(asset.headers);
    headers.set("Content-Type", "application/zip");
    headers.set("Content-Disposition", `attachment; filename="nano.md-${release.tag}-arm64.zip"`);
    headers.set("Cache-Control", "private, no-store, max-age=0");
    headers.set("X-Robots-Tag", "noindex, nofollow");
    const agent = request.headers.get("User-Agent") || "";
    const purpose = `${request.headers.get("Purpose") || ""} ${request.headers.get("Sec-Purpose") || ""}`;
    const excluded = cookie(request, "nano_md_analytics_excluded") === "true";
    const automated = /bot|crawler|spider|headless|lighthouse|curl|wget/i.test(agent) || /prefetch|prerender/i.test(purpose);
    if (env.DISABLE_DOWNLOAD_ANALYTICS !== "true" && request.method === "GET" && url.hostname === "nano.thirdeyeds.com" && !excluded && !automated) {
      const stored = cookie(request, visitorKey);
      const visitorId = stored && uuidPattern.test(stored) ? stored : crypto.randomUUID();
      headers.append("Set-Cookie", `${visitorKey}=${visitorId}; Path=/; Max-Age=31536000; SameSite=Lax; Secure`);
      const device = /iPad|Tablet/i.test(agent) || (/Android/i.test(agent) && !/Mobile/i.test(agent))
        ? "tablet" : /Mobi|Android|iPhone/i.test(agent) ? "mobile" : "desktop";
      // Send analytics in the background while the asset streams to the browser.
      ctx.waitUntil(recordDownload({
        id: crypto.randomUUID(), visitor_id: visitorId, event_type: "download", path: "/download",
        referrer: referrerHostname(request), device, region: null, download_url: release.downloadUrl,
      }));
    }
    return new Response(asset.body, { status: asset.status, headers });
  },
};
