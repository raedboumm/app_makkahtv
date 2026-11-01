import React, { useState, useEffect, useMemo, useRef } from "react";
import { createPortal } from "react-dom";
import "../styles/ProgramEpisodes.css";
import "../styles/videoCard.css";

const ProgramEpisodes = ({ title, episodes = [], pageSize = 4, autoIntervalMs = 5000 }) => {
  const [index, setIndex] = useState(0);
  const [prevIndex, setPrevIndex] = useState(0);
  const [isSliding, setIsSliding] = useState(false);
  const [gridSize, setGridSize] = useState(4);
  const SLIDE_MS = 450;
  const [isOpen, setIsOpen] = useState(false);
  const [playerSrc, setPlayerSrc] = useState(null);
  const [playerType, setPlayerType] = useState(null); // 'youtube' | 'video' | 'iframe'

  // Helper function to get grid size based on screen width
  const getGridSize = () => {
    return (window.innerWidth < 500) ? 1 :
      (window.innerWidth < 769) ? 2 :
        (window.innerWidth < 1024) ? 2 : 3;
  };

  // Update grid size on mount and resize
  useEffect(() => {
    const updateGridSize = () => {
      setGridSize(getGridSize());
    };

    updateGridSize();
    window.addEventListener('resize', updateGridSize);
    return () => window.removeEventListener('resize', updateGridSize);
  }, []);

  const safeEpisodes = useMemo(() => (Array.isArray(episodes) ? episodes.filter(Boolean) : []), [episodes]);
  const len = safeEpisodes.length;

  // touch/swipe refs
  const touchStartX = useRef(0);
  const touchStartY = useRef(0);
  const touchStartTime = useRef(0);
  const didSwipe = useRef(false);

  const makeWindow = (start) => {
    const src = safeEpisodes;
    const l = src.length;
    if (l === 0) return [];
    if (l <= gridSize) return src;
    const items = [];
    for (let i = 0; i < gridSize; i++) items.push(src[(start + i) % l]);
    return items;
  };

  const currItems = useMemo(() => makeWindow(index), [index, gridSize, safeEpisodes]);

  useEffect(() => {
    setIndex((i) => (len === 0 ? 0 : Math.min(Math.max(0, i), len - 1)));
  }, [len]);

  useEffect(() => {
    // Auto-advance the window by 1 every interval
    if (len <= 1 || autoIntervalMs <= 0) return;
    const id = setInterval(() => {
      setIndex((i) => {
        const next = (i + 1) % len;
        setPrevIndex(i);
        setIsSliding(true);
        return next;
      });
    }, autoIntervalMs);
    return () => clearInterval(id);
  }, [len, autoIntervalMs]);

  useEffect(() => {
    if (!isSliding) return;
    const t = setTimeout(() => setIsSliding(false), SLIDE_MS);
    return () => clearTimeout(t);
  }, [isSliding]);

  const getYouTubeId = (url = "") => {
    try {
      const u = new URL(url);
      if (u.hostname.includes("youtu.be")) return u.pathname.slice(1);
      if (u.hostname.includes("youtube.com")) return u.searchParams.get("v");
    } catch (e) { }
    return null;
  };

  const getYouTubeEmbed = (url = "") => {
    const id = getYouTubeId(url);
    if (!id) return null;
    return `https://www.youtube.com/embed/${id}?autoplay=1&rel=0&modestbranding=1`;
  };

  const handlePlay = (e, ep) => {
    if (e) e.preventDefault();
    if (!ep?.youtube) return;
    const ytEmbed = getYouTubeEmbed(ep.youtube);
    if (ytEmbed) {
      setPlayerType("youtube");
      setPlayerSrc(ytEmbed);
    } else if (/(\.mp4|\.webm|\.ogg)(\?|$)/i.test(ep.youtube)) {
      setPlayerType("video");
      setPlayerSrc(ep.youtube);
    } else {
      setPlayerType("iframe");
      setPlayerSrc(ep.youtube);
    }
    setIsOpen(true);
  };

  // Touch handlers for swipe navigation (mobile)
  const handleTouchStart = (e) => {
    const t = e.touches && e.touches[0];
    if (!t) return;
    touchStartX.current = t.clientX;
    touchStartY.current = t.clientY;
    touchStartTime.current = Date.now();
    didSwipe.current = false;
  };

  const handleTouchEnd = (e) => {
    // touchend doesn't have touches; use changedTouches
    const t = e.changedTouches && e.changedTouches[0];
    if (!t) return;
    const dx = t.clientX - touchStartX.current;
    const dy = t.clientY - touchStartY.current;
    const dt = Date.now() - (touchStartTime.current || 0);

    // require mostly horizontal movement, and a minimum distance
    const absDx = Math.abs(dx);
    const absDy = Math.abs(dy);
    const minDistance = 50; // px
    const maxVerticalRatio = 0.5; // horizontal must dominate

    if (absDx > minDistance && absDx > absDy * (1 / maxVerticalRatio)) {
      // it's a horizontal swipe
      didSwipe.current = true;
      if (dx < 0) {
        // swipe left -> next
        if (len > 0) {
          setPrevIndex(index);
          setIsSliding(true);
          setIndex((i) => (i + 1) % len);
        }
      } else {
        // swipe right -> prev
        if (len > 0) {
          setPrevIndex(index);
          setIsSliding(true);
          setIndex((i) => (i - 1 + len) % len);
        }
      }

      // clear the didSwipe flag shortly after to allow normal clicks later
      window.setTimeout(() => (didSwipe.current = false), 300);
    }
  };

  const closePlayer = () => {
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
    <div className="episodes-wrapper  "> 
      <h2 className="section-title">  <span className="title-bar"></span>{title}</h2>

      <div
        className="episodes-grid"
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        {currItems.map((ep, i) => (
          <a
            key={i}
            className="episode-card"
            href={ep.youtube || "#"}
            onClick={(e) => {
              // if a swipe was just detected, prevent click navigation
              if (didSwipe.current) {
                e.preventDefault();
                return;
              }
              if (!ep.youtube) {
                e.preventDefault();
              }
              handlePlay(e, ep);
            }}
          >
            <div className="episode-image">
              <img
                className="img-default"
                src={ep.image1 || ep.imagePoster || ep.image}
                alt={ep.program}
                loading="lazy"
              />
              <img
                className="img-hover"
                src={ep.image2 || ep.image1 || ep.imageWide || ep.image}
                alt=""
                loading="lazy"
              />
            </div>

            <div className="episode-hover">
              <h3 className="ep-program">{ep.program}</h3>
              <p className="ep-title">{ep.episode}</p>
              <p className="ep-time">{ep.time}</p>

              <div className="ep-actions">
                <button
                  className="ep-btn primary"
                  type="button"
                  onClick={(e) => { e.stopPropagation(); handlePlay(e, ep); }}
                >
                  <i className="fas fa-play"></i> مشاهدة
                </button>
              </div>
            </div>

          </a>
        ))}
      </div>

      {isOpen
        ? createPortal(
          <div className="video-modal" onClick={closePlayer} role="dialog" aria-modal="true">
            <div className="video-modal-content" onClick={(e) => e.stopPropagation()}>
              <button className="video-modal-close" onClick={closePlayer} aria-label="Close video">×</button>
              <div className="video-player-wrapper">
                {playerType === "youtube" && (
                  <iframe
                    title={"episode-player"}
                    src={playerSrc}
                    frameBorder="0"
                    allow="autoplay; fullscreen"
                    allowFullScreen
                  />
                )}

                {playerType === "video" && (
                  <video src={playerSrc} controls autoPlay playsInline />
                )}

                {playerType === "iframe" && (
                  <iframe
                    title={"episode-player"}
                    src={playerSrc}
                    frameBorder="0"
                    allow="autoplay; fullscreen"
                    allowFullScreen
                  />
                )}
              </div>
            </div>
          </div>,
          document.body
        )
        : null}

      <div
        className="episodes-pagination dots"
        style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: '35px' }}
      >
        {Array.from({ length: len }, (_, i) => (
          <button
            key={i}
            aria-label={`العنصر ${i + 1}`}
            onClick={() => {
              if (i === index) return;
              setPrevIndex(index);
              setIsSliding(true);
              setIndex(i);
            }}
            style={{
              width: i === index ? 12 : 10,
              height: i === index ? 12 : 10,
              borderRadius: '50%',
              border: '0',
              padding: 0,
              cursor: 'pointer',
              backgroundColor: i === index ? '#222' : '#c8c8c8',
              opacity: i === index ? 1 : 0.6,
              transition: 'opacity 0.2s ease, background-color 0.2s ease, width 0.2s ease, height 0.2s ease',
            }}
          />
        ))}
      </div>
    </div> 
  );
};

export default ProgramEpisodes;
