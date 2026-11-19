// src/services/siteConfig.js
//
// Settings managed from the back office (live stream URL + the two YouTube
// API configs). The back office is PHP that ships with the site build
// (public/api/index.php -> /api/index.php on the same domain), so it works on
// plain FTP hosting. Set VITE_BACKOFFICE_URL only to point somewhere else.
// Fetched once per visit; if the back office is unreachable or a value is empty, the built-in defaults below are used so the site never
// breaks because of it.

const BACKOFFICE_URL = (import.meta.env?.VITE_BACKOFFICE_URL || "").replace(/\/$/, "");
const ENV_YT_KEY = import.meta.env?.VITE_YOUTUBE_API_KEY || "";

export const DEFAULT_CONFIG = {
  live: {
    streamUrl: "https://media2.streambrothers.com:1936/8122/8122/playlist.m3u8",
  },
  library: {
    apiKey: ENV_YT_KEY,
    playlistId: "UUGJ2xTzBAM-uuxCShVDY88g",
  },
  playlists: {
    apiKey: ENV_YT_KEY,
    channelId: "UCGJ2xTzBAM-uuxCShVDY88g",
  },
};

const pick = (value, fallback) => (typeof value === "string" && value.trim() ? value.trim() : fallback);

const merge = (remote = {}) => ({
  live: {
    streamUrl: pick(remote.live?.streamUrl, DEFAULT_CONFIG.live.streamUrl),
  },
  library: {
    apiKey: pick(remote.library?.apiKey, DEFAULT_CONFIG.library.apiKey),
    playlistId: pick(remote.library?.playlistId, DEFAULT_CONFIG.library.playlistId),
  },
  playlists: {
    apiKey: pick(remote.playlists?.apiKey, DEFAULT_CONFIG.playlists.apiKey),
    channelId: pick(remote.playlists?.channelId, DEFAULT_CONFIG.playlists.channelId),
  },
});

let configPromise = null;

export const getSiteConfig = () => {
  if (configPromise) return configPromise;
  configPromise = (async () => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 6000);
    try {
      const res = await fetch(`${BACKOFFICE_URL}/api/index.php?action=config`, { signal: controller.signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return merge(await res.json());
    } catch (e) {
      console.warn("Back office config unavailable, using defaults:", e.message);
      return merge();
    } finally {
      clearTimeout(timer);
    }
  })();
  return configPromise;
};

// New CAPTCHA for the contact form: { token, image } (image is an SVG data URL).
export const fetchCaptcha = async () => {
  const res = await fetch(`${BACKOFFICE_URL}/api/index.php?action=captcha`, { cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.token || !data.image) throw new Error("تعذر تحميل رمز التحقق");
  return data;
};

// Sends the "تواصل معنا" form to the back office's messages table.
// payload must include captchaToken + captchaAnswer.
export const sendContactMessage = async (payload) => {
  const res = await fetch(`${BACKOFFICE_URL}/api/index.php?action=contact`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const data = await res.json().catch(() => ({}));
  // data.ok guards against a host that answers every path with index.html.
  if (!res.ok || !data.ok) throw new Error(data.error || "تعذر إرسال الرسالة، حاول مرة أخرى");
  return data;
};
