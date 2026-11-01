import React, { createContext, useContext, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";

const LiveStreamContext = createContext(null);

const STREAM_URL = "https://media2.streambrothers.com:1936/8122/8122/playlist.m3u8";

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

  useEffect(() => {
    const video = videoEl;
    if (!video) return;

    let hls;
    const start = async () => {
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

    start();

    return () => {
      if (hls) hls.destroy();
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
