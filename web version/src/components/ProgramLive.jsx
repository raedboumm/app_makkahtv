import React, { useState, useEffect, useMemo, useRef } from "react";
import "../styles/ProgramEpisodes.css";
import "../styles/videoCard.css";

const ProgramLive = ({ title, programs = [], pageSize = 2, autoIntervalMs = 5000 }) => {
  const [index, setIndex] = useState(0);
  const [prevIndex, setPrevIndex] = useState(0);
  const [isSliding, setIsSliding] = useState(false);
  const [gridSize, setGridSize] = useState(2);
  const SLIDE_MS = 500;

  // Helper function to get grid size based on screen width
  const getGridSize = () => {
    return (window.innerWidth < 500) ? 1 :
      (window.innerWidth < 769) ? 2 :
        (window.innerWidth < 1024) ? 3 : 4;
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

  const safePrograms = useMemo(() => (Array.isArray(programs) ? programs.filter(Boolean) : []), [programs]);
  const len = safePrograms.length;

  // touch/swipe refs
  const touchStartX = useRef(0);
  const touchStartY = useRef(0);
  const touchStartTime = useRef(0);
  const didSwipe = useRef(false);

  const makeWindow = (start) => {
    const src = safePrograms;
    const l = src.length;
    if (l === 0) return [];
    if (l <= gridSize) return src;
    const items = [];
    for (let i = 0; i < gridSize; i++) items.push(src[(start + i) % l]);
    return items;
  };

  const currItems = useMemo(() => makeWindow(index), [index, gridSize, safePrograms]);

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

  const handlePlay = (e, prog) => {
    if (e) e.preventDefault();
    if (!prog?.youtube) return;
    const ytEmbed = getYouTubeEmbed(prog.youtube);
    if (ytEmbed) {
      window.open(ytEmbed, '_blank');
    }
  };

  const handleTouchStart = (e) => {
    touchStartX.current = e.touches[0].clientX;
    touchStartY.current = e.touches[0].clientY;
    touchStartTime.current = Date.now();
    didSwipe.current = false;
  };

  const handleTouchMove = (e) => {
    if (!touchStartX.current || didSwipe.current) return;
    const dx = e.touches[0].clientX - touchStartX.current;
    const dy = e.touches[0].clientY - touchStartY.current;
    if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 50) {
      didSwipe.current = true;
      if (dx > 0) {
        // Swipe right: previous
        setIndex((i) => {
          const prev = (i - 1 + len) % len;
          setPrevIndex(i);
          setIsSliding(true);
          return prev;
        });
      } else {
        // Swipe left: next
        setIndex((i) => {
          const next = (i + 1) % len;
          setPrevIndex(i);
          setIsSliding(true);
          return next;
        });
      }
    }
  };

  const handleTouchEnd = () => {
    touchStartX.current = 0;
    touchStartY.current = 0;
    touchStartTime.current = 0;
  };

  if (len === 0) return null;

  return (
    <section id="program-episodes" className="program-episodes">
      <div className="container">
        <h2 className="section-title">
          <span className="title-bar"></span>{title}
        </h2>

        <div className="episodes-wrapper">
          <div
            className="episodes-grid"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
          >
            {currItems.map((prog, i) => (
              <div key={`${prog.program}-${i}`} className={`episode-card ${i === 0 ? 'active' : ''}`}>
                <div className="episode-image-wrapper">
                  <img
                    src={prog.image1 || prog.image2}
                    alt={prog.program}
                    className="episode-image"
                    loading="lazy"
                  />
                  <div className="episode-overlay">
                    <button
                      className="play-button"
                      onClick={(e) => handlePlay(e, prog)}
                      aria-label={`Play ${prog.program}`}
                    >
                      ▶
                    </button>
                  </div>
                </div>
                <div className="episode-info">
                  <div className="live-indicator">LIVE</div>
                  <h3 className="episode-program">{prog.program}</h3> 
                  <div className="episode-meta">
                    <span className="episode-time">{prog.time}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Navigation dots */}
          {len > gridSize && (
            <div className="episodes-dots">
              {Array.from({ length: len }, (_, i) => (
                <button
                  key={i}
                  className={`dot ${i === index ? 'active' : ''}`}
                  onClick={() => {
                    setPrevIndex(index);
                    setIndex(i);
                    setIsSliding(true);
                  }}
                  aria-label={`Go to slide ${i + 1}`}
                >
                  {i + 1}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

    </section>
  );
};

export default ProgramLive;