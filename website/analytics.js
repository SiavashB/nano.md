(() => {
  if (location.protocol !== "https:" || location.hostname !== "nano.thirdeyeds.com") return;
  if (navigator.webdriver || /bot|crawler|spider|headless|lighthouse/i.test(navigator.userAgent)) return;
  if (!globalThis.crypto?.randomUUID) return;

  const endpoint = "https://gesxgjsjrdwjpxebzqul.supabase.co/rest/v1/nano_events";
  const publishableKey = "sb_publishable_Za8_AYxM2gtYp0aHCuzIlg_bxRsYbUO";
  const visitorKey = "nano_md_visitor_id";

  function readCookie(name) {
    try {
      return document.cookie.split(";").map(part => part.trim())
        .find(part => part.startsWith(`${name}=`))?.slice(name.length + 1);
    } catch {
      return undefined;
    }
  }

  function writeCookie(name, value, maxAge = 31536000) {
    try {
      document.cookie = `${name}=${value}; Path=/; Max-Age=${maxAge}; SameSite=Lax; Secure`;
    } catch {
      // Downloads still work when storage is blocked; unique counts may be higher.
    }
  }

  function isExcluded() {
    try {
      const stored = localStorage.getItem("te_analytics_excluded");
      if (stored !== null) {
        writeCookie("nano_md_analytics_excluded", "true", stored === "true" ? 31536000 : 0);
        return stored === "true";
      }
    } catch {
      // The server and page-view tracker share the exclusion cookie when available.
    }
    return readCookie("nano_md_analytics_excluded") === "true";
  }

  if (isExcluded()) return;

  function getVisitorId() {
    const validId = value => value && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
    let stored;
    try { stored = localStorage.getItem(visitorKey); } catch { /* Cookies may still be available. */ }
    const cookieId = readCookie(visitorKey);
    const id = validId(stored) ? stored : validId(cookieId) ? cookieId : crypto.randomUUID();
    try { localStorage.setItem(visitorKey, id); } catch { /* Use the cookie or this page's ID. */ }
    writeCookie(visitorKey, id);
    return id;
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
      if (url.origin !== location.origin || url.pathname !== "/download" || isExcluded()) return;
      // Only Google Ads stays client-side; the Worker records the Supabase download event.
      if (typeof gtag === "function") gtag("event", "conversion", { send_to: "AW-18539154873/gUciCN2BgKsdELmblIhF", transport_type: "beacon" });
    } catch {
      // Ignore links that are not download routes.
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
