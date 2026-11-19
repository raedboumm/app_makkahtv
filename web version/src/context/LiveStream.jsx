import React, { createContext, useContext, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { getSiteConfig } from "../services/siteConfig";

const LiveStreamContext = createContext(null);


// Keeps one <video> + HLS connection alive for the whole app session,
// instead of letting it get destroyed and reconnected from scratch every
// time the homepage (and its live section) mounts/unmounts from routing.
// The video is moved via a portal into whichever page currently wants it
// (LiveStreamSlot), falling back to a hidden host so it keeps playing in
// the background when no page is showing it.
export const LiveStreamProvider = ({ children }) => {
  // A plain ref wouldn't work here: the <video> only exists once it's been
  // portaled somewhere (hiddenHost or an active slot), which itself only
  // exists after a render past the first one. A state-backed ref callback
  // lets the start-stream effect below depend on the element actually
  // showing up instead of firing once, too early, and never retrying.
  const [videoEl, setVideoEl] = useState(null);
  const [hiddenHost, setHiddenHost] = useState(null);
  const [activeHost, setActiveHost] = useState(null);
  const hlsRef = useRef(null);

  useEffect(() => {
    const video = videoEl;
    if (!video) return;

    let hls;
    let cancelled = false;
    const start = async () => {
      // Stream URL is managed from the back office (falls back to the default).
      const { live } = await getSiteConfig();
      const STREAM_URL = live.streamUrl;
      if (cancelled) return;

      video.muted = true;
      video.autoplay = true;
      video.playsInline = true;

      // Safari supports HLS natively
      if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = STREAM_URL;
        try {
          await video.play();
        } catch (e) {}
        return;
      }

      const Hls = (await import("hls.js")).default;
      if (cancelled) return;
      if (Hls.isSupported()) {
        hls = new Hls({ enableWorker: true, lowLatencyMode: true });
        hls.loadSource(STREAM_URL);
        hls.attachMedia(video);

        hls.on(Hls.Events.MANIFEST_PARSED, async () => {
          try {
            await video.play();
          } catch (e) {}
        });

        hls.on(Hls.Events.ERROR, (_, data) => {
          console.error("HLS error:", data);
        });
      }
    };

    start().then(() => {
      if (!cancelled) hlsRef.current = hls || null;
    });

    return () => {
      cancelled = true;
      hlsRef.current = null;
      if (hls) hls.destroy();
    };
  }, [videoEl]);

  // Only one thing should make sound at a time: while any other player is
  // on the page (a YouTube/other iframe in a modal or the home hero, or
  // another <video> such as the /live page), pause the live stream and stop
  // downloading it. When the last one closes, resume at the live edge.
  useEffect(() => {
    const live = videoEl;
    if (!live) return;

    let pausedByUs = false;

    const otherPlayerOpen = () => {
      if (document.querySelector("iframe:not([data-live-ignore])")) return true;
      return Array.from(document.querySelectorAll("video")).some((v) => v !== live);
    };

    const sync = () => {
      const hls = hlsRef.current;
      if (otherPlayerOpen()) {
        if (!pausedByUs && !live.paused) {
          pausedByUs = true;
          live.pause();
          if (hls) hls.stopLoad();
        }
      } else if (pausedByUs) {
        pausedByUs = false;
        if (hls) {
          hls.startLoad(-1);
          if (Number.isFinite(hls.liveSyncPosition)) live.currentTime = hls.liveSyncPosition;
        }
        live.play().catch(() => {});
      }
    };

    // Also catch a second <video> that starts playing without being newly added.
    const onPlay = (e) => {
      if (e.target !== live && e.target instanceof HTMLMediaElement) sync();
    };

    const observer = new MutationObserver(sync);
    observer.observe(document.body, { childList: true, subtree: true });
    document.addEventListener("play", onPlay, true);
    sync();

    return () => {
      observer.disconnect();
      document.removeEventListener("play", onPlay, true);
    };
  }, [videoEl]);

  const register = (hostEl) => setActiveHost(hostEl);
  const unregister = (hostEl) => setActiveHost((cur) => (cur === hostEl ? null : cur));

  const portalTarget = activeHost || hiddenHost;

  return (
    <LiveStreamContext.Provider value={{ register, unregister }}>
      {children}

      {/* Always-mounted fallback host: keeps the stream playing off-screen
          when no page currently wants to display it. */}
      <div
        ref={setHiddenHost}
        aria-hidden="true"
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          width: 1,
          height: 1,
          overflow: "hidden",
          opacity: 0,
          pointerEvents: "none",
        }}
      />

      {portalTarget &&
        createPortal(
          <video
            ref={setVideoEl}
            autoPlay
            muted
            playsInline
            loop
            controls
            preload="auto"
            onLoadedMetadata={(e) => {
              e.currentTarget.play().catch(() => {});
            }}
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              objectFit: "cover",
              background: "#000",
            }}
          />,
          portalTarget
        )}
    </LiveStreamContext.Provider>
  );
};

// Renders the docking element that the persistent live video gets portaled
// into while this component is mounted (e.g. on the homepage's hero area).
export const LiveStreamSlot = (props) => {
  const ctx = useContext(LiveStreamContext);
  const hostRef = useRef(null);

  useEffect(() => {
    if (!ctx || !hostRef.current) return;
    const el = hostRef.current;
    ctx.register(el);
    return () => ctx.unregister(el);
  }, [ctx]);

  return <div ref={hostRef} {...props} />;
};
