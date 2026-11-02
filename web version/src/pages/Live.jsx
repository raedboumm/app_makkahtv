import React, { useEffect, useRef, useState } from "react";
import "../styles/live.css";

const STREAM_URL = "https://media2.streambrothers.com:1936/8122/8122/playlist.m3u8";

const LivePage = () => {
  const [started, setStarted] = useState(false);
  const videoRef = useRef(null);

  // The <video> is rendered by React (never via innerHTML, which would
  // delete React-owned nodes), and the hls.js instance is torn down when
  // leaving the page so the stream stops downloading.
  useEffect(() => {
    if (!started) return;
    const video = videoRef.current;
    if (!video) return;

    let hls;
    let cancelled = false;
    (async () => {
      try {
        if (video.canPlayType("application/vnd.apple.mpegurl")) {
          // Safari
          video.src = STREAM_URL;
          await video.play().catch(() => {});
          return;
        }
        // Other browsers via hls.js (dynamic import)
        const { default: Hls } = await import("hls.js");
        if (cancelled) return;
        if (Hls.isSupported()) {
          hls = new Hls();
          hls.loadSource(STREAM_URL);
          hls.attachMedia(video);
        } else {
          video.src = STREAM_URL;
          await video.play().catch(() => {});
        }
      } catch (e) {
        /* no-op */
      }
    })();

    return () => {
      cancelled = true;
      if (hls) hls.destroy();
      video.removeAttribute("src");
      video.load();
    };
  }, [started]);

  const handleStartLive = () => setStarted(true);

  return (
    <div className="live-page">
      <div className="live-container">
        <div className="live-box">
          {/* ✅ Header Bar */}
          <div className="live-header">
            <div className="live-title">
              <span className="live-dot"></span>
              <h1>البث المباشر - قناة مكة</h1>
            </div>
            <span className="live-badge">مباشر</span>
          </div>

          {/* ✅ Video Embed (thumbnail + play button → live on click) */}
          <div className="video-wrapper">
            {started ? (
              <video
                ref={videoRef}
                controls
                autoPlay
                muted
                playsInline
                title="Makkah Live Stream"
                style={{
                  position: "absolute",
                  inset: 0,
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                  display: "block",
                  background: "#000",
                }}
              />
            ) : (
            <div
              className="absolute top-0 left-0 w-full h-full"
              role="button"
              tabIndex={0}
              aria-label="تشغيل البث المباشر"
              onClick={handleStartLive}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  handleStartLive(e);
                }
              }}
              style={{
                cursor: "pointer",
                overflow: "hidden",
                background: "#000",
                position: "absolute",
                inset: 0,
              }}
            >
              {/* thumbnail */}
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  backgroundImage:
                    "url('https://makkahlive.net/images/MakkahLiveCover.jpg')",
                  backgroundSize: "cover",
                  backgroundPosition: "center",
                  filter: "brightness(0.85)",
                }}
              />
              {/* play button */}
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  display: "grid",
                  placeItems: "center",
                }}
              >
                <div
                  style={{
                    width: 84,
                    height: 84,
                    borderRadius: "50%",
                    background: "rgba(255,255,255,0.92)",
                    boxShadow: "0 10px 35px rgba(0,0,0,.28)",
                    display: "grid",
                    placeItems: "center",
                  }}
                >
                  <svg width="30" height="30" viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M8 5v14l11-7z" fill="black" />
                  </svg>
                </div>

                {/* LIVE chip (optional) */}
                <div
                  style={{
                    position: "absolute",
                    top: 12,
                    right: 12,
                    padding: "6px 10px",
                    borderRadius: 999,
                    background: "rgba(255,0,0,0.95)",
                    color: "#fff",
                    fontSize: 12,
                    fontWeight: 800,
                    letterSpacing: 0.5,
                    textTransform: "uppercase",
                  }}
                >
                  Live
                </div>
              </div>
            </div>
            )}
          </div>

          {/* ✅ Description */}
          <div className="live-content">
            <h2>البث المباشر من المسجد الحرام</h2>
            <p>
              شاهد البث المباشر على مدار الساعة من المسجد الحرام في مكة المكرمة.
              متابعة الصلوات الخمس والشعائر الدينية مباشرة.
            </p>

            <div className="live-info">
              <div className="info-item">
                <i className="fas fa-users"></i>
                <span>12,453 مشاهد حالياً</span>
              </div>
              <div className="info-item">
                <i className="fas fa-clock"></i>
                <span>بث مباشر 24/7</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LivePage;
