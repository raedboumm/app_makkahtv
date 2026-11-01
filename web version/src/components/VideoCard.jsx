import React, { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import "../styles/videoCard.css";
import { formatViewCount } from "../services/youtube";

const FALLBACK_THUMB = "https://placehold.co/800x450?text=No+Image";

function getYouTubeId(url = "") {
  try {
    // handles: https://www.youtube.com/watch?v=ID, https://youtu.be/ID, & URL with params
    const u = new URL(url);
    if (u.hostname.includes("youtu.be")) return u.pathname.slice(1);
    if (u.hostname.includes("youtube.com")) return u.searchParams.get("v");
  } catch (e) { }
  return null;
}

function getYouTubeEmbed(url = "") {
  const id = getYouTubeId(url);
  if (!id) return null;
  // use the privacy-enhanced youtube-nocookie domain and include origin to avoid some embed restrictions
  // ensure controls and playsinline are enabled so pause/volume/fullscreen UI is visible
  const origin = typeof window !== 'undefined' ? encodeURIComponent(window.location.origin) : '';
  return `https://www.youtube-nocookie.com/embed/${id}?autoplay=1&rel=0&modestbranding=1&controls=1&playsinline=1&origin=${origin}`;
}

const VideoCard = ({ video }) => {
  const [views, setViews] = useState(video?.view_count ?? 0);
  const [isOpen, setIsOpen] = useState(false);
  const [playerSrc, setPlayerSrc] = useState(null);
  const [playerType, setPlayerType] = useState(null); // 'youtube' | 'video' | 'iframe'
  // map Arabic video type names to Font Awesome icon classes
  const typeIconMap = {
    "صلاة": "fas fa-mosque",
    "خطبة": "fas fa-bullhorn",
    "برنامج": "fas fa-tv",
    "تعليمي": "fas fa-graduation-cap",
    "درس": "fas fa-graduation-cap",
    "أذان": "fas fa-bell",
    "لقاء": "fas fa-comments",
    "تلاوة": "fas fa-music",
    "مشاهد": "fas fa-video"
  };

  const getTypeIcon = (t) => {
    if (!t) return "fas fa-tag";
    return typeIconMap[t] || "fas fa-tag";
  };
  const getThumbnail = () => {
    if (video?.thumbnail_url) return video.thumbnail_url;
    const ytId = getYouTubeId(video?.video_url);
    if (ytId) return `https://img.youtube.com/vi/${ytId}/hqdefault.jpg`;
    return FALLBACK_THUMB;
  };

  const formatDuration = (seconds) => {
    if (!seconds) return "بث مباشر";
    const mins = Math.floor(seconds / 60);
    return `${mins} دقيقة`;
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return "";
    const date = new Date(dateStr);
    return date.toLocaleDateString("ar-SA");
  };

  const handlePlay = () => {
    // Increment view count locally (no backend call)
    setViews((v) => v + 1);

    // open fullscreen modal player instead of new tab
    if (video?.video_url) {
      const ytEmbed = getYouTubeEmbed(video.video_url);
      if (ytEmbed) {
        setPlayerType("youtube");
        setPlayerSrc(ytEmbed);
      } else if (/(\.mp4|\.webm|\.ogg)(\?|$)/i.test(video.video_url)) {
        setPlayerType("video");
        setPlayerSrc(video.video_url);
      } else {
        // fallback to iframe for other providers
        setPlayerType("iframe");
        setPlayerSrc(video.video_url);
      }
      setIsOpen(true);
    }
  };

  const closePlayer = async () => {
    setIsOpen(false);
    setPlayerSrc(null);
    setPlayerType(null);
  };

  useEffect(() => {
    const onKey = (e) => {
      if (e.key === "Escape" && isOpen) closePlayer();
    };
    if (isOpen) document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [isOpen]);
  return (
    <>
      <div className="video-card">
        <div className="video-thumb">
          <img
            src={getThumbnail()}
            alt={video?.title_ar || "video"}
            onError={(e) => {
              if (e.currentTarget.src !== FALLBACK_THUMB) {
                e.currentTarget.src = FALLBACK_THUMB;
              }
            }}
            onClick={handlePlay}
            style={{ cursor: "pointer" }}
          />

          {/* Overlay Play Icon (clickable) */}
          <div className="video-overlay" onClick={handlePlay} role="button" aria-label="Play video">
            <i className="fas fa-play-circle" />
          </div>

          {/* Duration or Live Badge */}
          <div className="video-duration">
            {video?.is_live ? (
              <span className="live-badge">
                <i className="fas fa-circle" /> مباشر
              </span>
            ) : (
              formatDuration(video?.duration)
            )}
          </div>
        </div>

        <div className="video-content">
          {/* badges above title: type first, then category (same style) */}
          {video?.type_name && (
            <span className="video-category" title="نوع الفيديو">
              <i className={getTypeIcon(video?.type_name)} aria-hidden="true" />
              <span className="video-category-text">{video.type_name}</span>
            </span>
          )}
          {video?.category_name && (
            <span className="video-category" title="التصنيف">
              {video?.category_icon && <i className={video.category_icon} />} {video.category_name}
            </span>
          )}

          <h3 className="video-title">{video?.title_ar}</h3>
          <p className="video-desc">{video?.description_ar}</p>

          <div className="video-meta">
            <span>
              <i className="far fa-clock" /> {formatDate(video?.publish_date)}
            </span>
            <span>
              <i className="far fa-eye" /> {formatViewCount(views)}
            </span>
          </div>
        </div>
      </div>

      {isOpen
        ? createPortal(
          <div className="video-modal" onClick={closePlayer} role="dialog" aria-modal="true">
            <div className="video-modal-content" onClick={(e) => e.stopPropagation()}>
              <button className="video-modal-close" onClick={closePlayer} aria-label="Close video">×</button>
              <div className="video-player-wrapper">
                {playerType === "youtube" && (
                  <iframe
                    title={video?.title_ar || "video-player"}
                    src={playerSrc}
                    frameBorder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowFullScreen
                    loading="lazy"
                    style={{ zIndex: 1 }}
                  />
                )}

                {playerType === "video" && (
                  <video src={playerSrc} controls autoPlay playsInline style={{ zIndex: 1 }} />
                )}

                {playerType === "iframe" && (
                  <iframe
                    title={video?.title_ar || "video-player"}
                    src={playerSrc}
                    frameBorder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowFullScreen
                    loading="lazy"
                    style={{ zIndex: 1 }}
                  />
                )}
              </div>

      
            </div>
          </div>,
          document.body
        )
        : null}
    </>
  );
};

export default VideoCard;
