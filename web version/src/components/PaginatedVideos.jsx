import React, { useEffect, useMemo, useState } from 'react';
import VideoCard from './VideoCard.jsx';

class CardBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch() { }
  render() { return this.state.hasError ? null : this.props.children; }
}

// Sliding window over provided videos: shows 4, advances by 1 with horizontal slide
const PaginatedVideos = ({ videos = [], pageSize = 4, title = 'أحدث الفيديوهات', autoIntervalMs = 5000 }) => {
  // Limit to top 8 videos only (business rule per request)
  const limitedVideos = useMemo(() => (Array.isArray(videos) ? videos.slice(0, 8) : []), [videos]);
  const [index, setIndex] = useState(0); // start index of the visible window
  const [prevIndex, setPrevIndex] = useState(0);
  const [isSliding, setIsSliding] = useState(false);
  const [gridSize, setGridSize] = useState(4);
  const SLIDE_MS = 450;

  // Helper function to get grid size based on screen width
  const getGridSize = () => {
    return (window.innerWidth < 640) ? 1 :
      (window.innerWidth < 900) ? 2 :
        (window.innerWidth < 1200) ? 3 : 4;
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

  // Work only with limited sanitized list
  const safeVideos = useMemo(() => limitedVideos.filter(Boolean), [limitedVideos]);
  const len = safeVideos.length;

  // Publish a lightweight cache to reuse details (e.g., description_ar) in other widgets
  useEffect(() => {
    if (typeof window !== 'undefined') {
      window.__VIDEOS_BY_ID__ = window.__VIDEOS_BY_ID__ || {};
      let touched = false;
      safeVideos.forEach((v) => {
        if (!v) return;
        const key = v.id || v._id;
        if (key) {
          window.__VIDEOS_BY_ID__[key] = { ...(window.__VIDEOS_BY_ID__[key] || {}), ...v };
          touched = true;
        }
        if (v.slug) {
          window.__VIDEOS_BY_ID__[v.slug] = { ...(window.__VIDEOS_BY_ID__[v.slug] || {}), ...v };
          touched = true;
        }
      });
      if (touched && typeof window.dispatchEvent === 'function') {
        try { window.dispatchEvent(new CustomEvent('videosCacheUpdated')); } catch (_) { }
      }
    }
  }, [safeVideos]);

  const makeWindow = (start) => {
    const src = safeVideos;
    const l = src.length;
    if (l === 0) return [];
    if (l <= gridSize) return src;
    const items = [];
    for (let i = 0; i < gridSize; i++) items.push(src[(start + i) % l]);
    return items;
  };

  const prevItems = useMemo(() => makeWindow(prevIndex), [prevIndex, gridSize, safeVideos]);
  const currItems = useMemo(() => makeWindow(index), [index, gridSize, safeVideos]);

  useEffect(() => {
    // Clamp index when list changes
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

  return (
    <section className="videos-wrapper">
      <div className="container">
        <h2 className="section-title">
          <span className="title-bar"></span> {title}
        </h2>

        <div className="video-slider">
          <div
            className={`slider-track ${isSliding ? 'is-sliding' : ''}`}
            style={{ '--slide-ms': `${SLIDE_MS}ms` }}
          >
            <div className="slider-panel">

            </div>
            <div className="slider-panel">
              <div className="grid video-grid">
                {currItems.length === 0 ? (
                  <div style={{ gridColumn: '1 / -1', textAlign: 'center' }}>لا توجد فيديوهات</div>
                ) : (
                  currItems.map((video, i) => (
                    <CardBoundary key={video?.id || video?._id || video?.slug || video?.url || `cur-${i}`}>
                      <VideoCard video={video} />
                    </CardBoundary>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>

        <div
          className="videos-pagination dots"
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
    </section>
  );
};

export default PaginatedVideos;

