(() => {
  if (location.protocol !== "https:" || location.hostname !== "nano.thirdeyeds.com") return;
  if (navigator.webdriver || /bot|crawler|spider|headless|lighthouse/i.test(navigator.userAgent)) return;
  if (!globalThis.crypto?.randomUUID) return;

  const endpoint = "https://gesxgjsjrdwjpxebzqul.supabase.co/rest/v1/nano_events";
  const publishableKey = "sb_publishable_Za8_AYxM2gtYp0aHCuzIlg_bxRsYbUO";
  const visitorKey = "nano_md_visitor_id";

  function isExcluded() {
    try {
      return localStorage.getItem("te_analytics_excluded") === "true";
    } catch {
      return false;
    }
  }

  if (isExcluded()) return;

  function getVisitorId() {
    const fallback = crypto.randomUUID();
    try {
      const stored = localStorage.getItem(visitorKey);
      if (stored && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(stored)) return stored;
      localStorage.setItem(visitorKey, fallback);
    } catch {
      // Without storage, page views and clicks share an ID for this page load only.
    }
    return fallback;
  }

  function getReferrer() {
    try {
      return new URL(document.referrer).hostname.slice(0, 500) || null;
    } catch {
      return null;
    }
  }

  function getRegion() {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone?.slice(0, 100) || null;
    } catch {
      return null;
    }
  }

  function getDevice() {
    const agent = navigator.userAgent;
    if (/iPad|Tablet/i.test(agent) || (/Android/i.test(agent) && !/Mobile/i.test(agent)) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)) return "tablet";
    return /Mobi|Android|iPhone/i.test(agent) ? "mobile" : "desktop";
  }

  const context = {
    visitor_id: getVisitorId(),
    path: location.pathname.slice(0, 300),
    referrer: getReferrer(),
    device: getDevice(),
    region: getRegion(),
  };

  function track(eventType, downloadUrl = null) {
    if (isExcluded()) return;
    try {
      fetch(endpoint, {
        method: "POST",
        headers: {
          apikey: publishableKey,
          "Content-Type": "application/json",
          Prefer: "return=minimal",
        },
        body: JSON.stringify({ ...context, id: crypto.randomUUID(), event_type: eventType, download_url: downloadUrl }),
        keepalive: true,
        credentials: "omit",
        referrerPolicy: "no-referrer",
      }).catch(() => {});
    } catch {
      // Analytics failures must never interrupt navigation or downloads.
    }
  }

  function trackDownload(event) {
    if (!event.isTrusted || event.defaultPrevented || !(event.target instanceof Element)) return;
    const anchor = event.target.closest("a[href]");
    if (!anchor) return;
    try {
      const url = new URL(anchor.href);
      if (url.origin !== "https://github.com" || url.username || url.password) return;
      if (!/^\/SiavashB\/nano\.md\/releases\/download\/[^/]+\/[^/]+$/.test(url.pathname)) return;
      const downloadUrl = `${url.origin}${url.pathname}`;
      if (downloadUrl.length <= 1000) {
        track("download", downloadUrl);
        if (typeof gtag === "function") gtag("event", "conversion", { send_to: "AW-18539154873/gUciCN2BgKsdELmblIhF", transport_type: "beacon" });
      }
    } catch {
      // Ignore links that are not valid release asset URLs.
    }
  }

  document.addEventListener("click", event => {
    if (event.button === 0) trackDownload(event);
  });
  document.addEventListener("auxclick", event => {
    if (event.button === 1) trackDownload(event);
  });
  track("page_view");
})();
