// src/services/youtube.js
import axios from "axios";

const API_KEY = import.meta.env?.VITE_YOUTUBE_API_KEY;
const YOUTUBE_API_BASE = "https://www.googleapis.com/youtube/v3";

// Real view counts barely move minute to minute, so we cache them for a
// while to avoid re-hitting the API (and burning quota) on every page
// load / remount / StrictMode double-effect.
const CACHE_KEY = "makkah_yt_view_counts";
const CACHE_TTL_MS = 15 * 60 * 1000; // 15 minutes

const readCache = () => {
  try {
    return JSON.parse(localStorage.getItem(CACHE_KEY)) || {};
  } catch (e) {
    return {};
  }
};

const writeCache = (cache) => {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
  } catch (e) {}
};

export const extractYouTubeId = (url = "") => {
  try {
    const u = new URL(url);
    if (u.hostname.includes("youtu.be")) return u.pathname.slice(1);
    if (u.hostname.includes("youtube.com")) return u.searchParams.get("v");
  } catch (e) {}
  return null;
};

// De-dupe concurrent requests for the same set of ids (StrictMode double-mount,
// multiple components asking for the same videos at once, etc.) so only one
// network call ever goes out at a time for a given id set.
const inFlight = new Map();

// Returns { [videoId]: viewCount } using real YouTube Data API v3 statistics.
// Serves from the short-lived cache when possible; only calls the API for
// ids that are missing or stale, in a single batched request.
export const fetchViewCounts = async (videoIds = []) => {
  const ids = [...new Set(videoIds.filter(Boolean))];
  if (!API_KEY || ids.length === 0) return {};

  const now = Date.now();
  const cache = readCache();

  const fresh = {};
  const stale = [];
  ids.forEach((id) => {
    const entry = cache[id];
    if (entry && now - entry.ts < CACHE_TTL_MS) {
      fresh[id] = entry.count;
    } else {
      stale.push(id);
    }
  });

  if (stale.length === 0) return fresh;

  const requestKey = stale.slice().sort().join(",");
  if (inFlight.has(requestKey)) {
    const fetched = await inFlight.get(requestKey);
    return { ...fresh, ...fetched };
  }

  const promise = (async () => {
    try {
      const { data } = await axios.get(`${YOUTUBE_API_BASE}/videos`, {
        params: { part: "statistics", id: stale.join(","), key: API_KEY },
      });

      const result = {};
      (data.items || []).forEach((item) => {
        result[item.id] = Number(item.statistics?.viewCount || 0);
      });

      const nextCache = readCache();
      stale.forEach((id) => {
        if (result[id] != null) {
          nextCache[id] = { count: result[id], ts: Date.now() };
        }
      });
      writeCache(nextCache);

      return result;
    } catch (e) {
      console.error("YouTube API error:", e);
      return {};
    } finally {
      inFlight.delete(requestKey);
    }
  })();

  inFlight.set(requestKey, promise);

  const fetched = await promise;
  return { ...fresh, ...fetched };
};

// Human-readable view count (1234567 -> "1.2M", 4500 -> "4.5K").
export const formatViewCount = (count) => {
  const n = Number(count) || 0;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1).replace(/\.0$/, "")}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1).replace(/\.0$/, "")}K`;
  return `${n}`;
};

// "PT1H2M3S" -> 3723 (seconds)
const parseISODuration = (iso = "") => {
  const m = iso.match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!m) return 0;
  const h = parseInt(m[1] || 0, 10);
  const min = parseInt(m[2] || 0, 10);
  const s = parseInt(m[3] || 0, 10);
  return h * 3600 + min * 60 + s;
};

// Makkah TV's channel — resolved once via forHandle and hardcoded since a
// channel's id/uploads playlist never change, so we don't burn quota
// re-resolving it on every visit.
const CHANNEL_ID = "UCGJ2xTzBAM-uuxCShVDY88g";
const UPLOADS_PLAYLIST_ID = "UUGJ2xTzBAM-uuxCShVDY88g";

// Generic localStorage list cache shared by the catalog, playlists, and
// per-playlist video fetches below.
const readListCache = (key, ttlMs) => {
  try {
    const raw = JSON.parse(localStorage.getItem(key));
    if (!raw || !raw.ts || !Array.isArray(raw.list)) return null;
    if (Date.now() - raw.ts > ttlMs) return null;
    return raw.list;
  } catch (e) {
    return null;
  }
};

const writeListCache = (key, list) => {
  try {
    localStorage.setItem(key, JSON.stringify({ ts: Date.now(), list }));
  } catch (e) {}
};

// Full-catalog / per-playlist fetches are bigger, so they get a longer-lived
// cache than the lightweight view-count cache above.
const LIST_CACHE_TTL_MS = 3 * 60 * 60 * 1000; // 3 hours

// Fetches a single page of a playlist's items.
const fetchPlaylistItemsPage = async (playlistId, pageToken) => {
  const { data } = await axios.get(`${YOUTUBE_API_BASE}/playlistItems`, {
    params: {
      part: "snippet,contentDetails",
      playlistId,
      maxResults: 50,
      pageToken: pageToken || undefined,
      key: API_KEY,
    },
  });

  const items = [];
  (data.items || []).forEach((item) => {
    const videoId = item.contentDetails?.videoId;
    const publishedAt = item.contentDetails?.videoPublishedAt || item.snippet?.publishedAt;
    if (!videoId || !publishedAt) return; // skip private/unpublished entries
    items.push({
      id: videoId,
      title: item.snippet?.title || "",
      thumbnail:
        item.snippet?.thumbnails?.high?.url ||
        item.snippet?.thumbnails?.medium?.url ||
        item.snippet?.thumbnails?.default?.url ||
        "",
      publishedAt,
    });
  });

  return { items, nextPageToken: data.nextPageToken || "" };
};

// Walks every page of a playlist (uploads playlist or any other), returning
// [{ id, title, thumbnail, publishedAt }] in the playlist's own order.
const fetchPlaylistItemsAll = async (playlistId) => {
  const all = [];
  let pageToken = "";
  do {
    const { items, nextPageToken } = await fetchPlaylistItemsPage(playlistId, pageToken);
    all.push(...items);
    pageToken = nextPageToken;
  } while (pageToken);

  return all;
};

// Batch-fetches real stats + duration for a list of {id, ...} items,
// 50 ids per call, in parallel, and merges them in.
const withVideoStats = async (items) => {
  const idChunks = [];
  for (let i = 0; i < items.length; i += 50) {
    idChunks.push(items.slice(i, i + 50).map((v) => v.id));
  }

  const statsMap = {};
  await Promise.all(
    idChunks.map(async (ids) => {
      if (ids.length === 0) return;
      const { data } = await axios.get(`${YOUTUBE_API_BASE}/videos`, {
        params: { part: "statistics,contentDetails", id: ids.join(","), key: API_KEY },
      });
      (data.items || []).forEach((v) => {
        statsMap[v.id] = {
          viewCount: Number(v.statistics?.viewCount || 0),
          duration: parseISODuration(v.contentDetails?.duration || ""),
        };
      });
    })
  );

  return items.map((v) => ({
    ...v,
    viewCount: statsMap[v.id]?.viewCount ?? 0,
    duration: statsMap[v.id]?.duration ?? 0,
  }));
};

const CHANNEL_CACHE_KEY = "makkah_yt_channel_videos";
let channelFetchInFlight = null;
let channelProgressListeners = new Set();
let channelProgressSnapshot = [];

// Fetches every video ever uploaded to the channel (title, thumbnail,
// publish date, duration, real view count) for the "مكتبة البرامج" page.
// Served from a 3h cache when possible; concurrent calls share one fetch.
//
// Pass onProgress to get the real (never fake) results as each page loads
// instead of waiting for the whole ~1200-video catalog — the page can show
// what already arrived right away. Pages are fetched one at a time (items,
// then that page's real stats, then the next page) rather than bursting many
// requests at once, which is both gentler on the API and makes the first
// batch of real data land sooner.
export const fetchAllChannelVideos = async ({ onProgress } = {}) => {
  const cached = readListCache(CHANNEL_CACHE_KEY, LIST_CACHE_TTL_MS);
  if (cached) return cached;

  if (onProgress) {
    channelProgressListeners.add(onProgress);
    if (channelProgressSnapshot.length > 0) onProgress(channelProgressSnapshot.slice());
  }

  if (channelFetchInFlight) return channelFetchInFlight;

  channelProgressSnapshot = [];
  channelFetchInFlight = (async () => {
    if (!API_KEY) return [];
    const allVideos = [];
    try {
      let pageToken = "";
      do {
        const { items, nextPageToken } = await fetchPlaylistItemsPage(UPLOADS_PLAYLIST_ID, pageToken);
        const pageWithStats = await withVideoStats(items);
        allVideos.push(...pageWithStats);
        channelProgressSnapshot = allVideos.slice();
        channelProgressListeners.forEach((cb) => cb(channelProgressSnapshot));
        pageToken = nextPageToken;
      } while (pageToken);

      writeListCache(CHANNEL_CACHE_KEY, allVideos);
      return allVideos;
    } catch (e) {
      console.error("YouTube channel fetch error:", e);
      // Keep whatever already streamed in rather than wiping it out.
      if (allVideos.length > 0) writeListCache(CHANNEL_CACHE_KEY, allVideos);
      return allVideos;
    } finally {
      channelFetchInFlight = null;
      channelProgressListeners.clear();
    }
  })();

  return channelFetchInFlight;
};

const PLAYLISTS_CACHE_KEY = "makkah_yt_playlists";
let playlistsFetchInFlight = null;

// Fetches the channel's real playlists ("قوائم التشغيل" tab): id, title,
// thumbnail and video count. Cached the same way as the full catalog.
export const fetchChannelPlaylists = async () => {
  const cached = readListCache(PLAYLISTS_CACHE_KEY, LIST_CACHE_TTL_MS);
  if (cached) return cached;

  if (playlistsFetchInFlight) return playlistsFetchInFlight;

  playlistsFetchInFlight = (async () => {
    if (!API_KEY) return [];
    try {
      const playlists = [];
      let pageToken = "";
      do {
        const { data } = await axios.get(`${YOUTUBE_API_BASE}/playlists`, {
          params: {
            part: "snippet,contentDetails",
            channelId: CHANNEL_ID,
            maxResults: 50,
            pageToken: pageToken || undefined,
            key: API_KEY,
          },
        });

        (data.items || []).forEach((p) => {
          playlists.push({
            id: p.id,
            title: p.snippet?.title || "",
            thumbnail:
              p.snippet?.thumbnails?.high?.url ||
              p.snippet?.thumbnails?.medium?.url ||
              p.snippet?.thumbnails?.default?.url ||
              "",
            itemCount: p.contentDetails?.itemCount ?? 0,
          });
        });

        pageToken = data.nextPageToken || "";
      } while (pageToken);

      writeListCache(PLAYLISTS_CACHE_KEY, playlists);
      return playlists;
    } catch (e) {
      console.error("YouTube playlists fetch error:", e);
      return [];
    } finally {
      playlistsFetchInFlight = null;
    }
  })();

  return playlistsFetchInFlight;
};

const playlistVideosInFlight = new Map();

// Fetches the real videos inside one specific playlist (drill-down from
// "قوائم التشغيل"), in the playlist's own order.
export const fetchPlaylistVideos = async (playlistId) => {
  if (!playlistId) return [];

  const cacheKey = `makkah_yt_playlist_${playlistId}`;
  const cached = readListCache(cacheKey, LIST_CACHE_TTL_MS);
  if (cached) return cached;

  if (playlistVideosInFlight.has(playlistId)) return playlistVideosInFlight.get(playlistId);

  const promise = (async () => {
    if (!API_KEY) return [];
    try {
      const items = await fetchPlaylistItemsAll(playlistId);
      const videos = await withVideoStats(items);
      writeListCache(cacheKey, videos);
      return videos;
    } catch (e) {
      console.error("YouTube playlist videos fetch error:", e);
      return [];
    } finally {
      playlistVideosInFlight.delete(playlistId);
    }
  })();

  playlistVideosInFlight.set(playlistId, promise);
  return promise;
};
