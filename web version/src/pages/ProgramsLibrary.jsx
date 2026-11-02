import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import VideoCard from "../components/VideoCard";
import "../styles/videos.css";
import "../styles/library.css";
import "../styles/ProgramEpisodes.css";
import { fetchAllChannelVideos, fetchChannelPlaylists, fetchPlaylistVideos } from "../services/youtube";

const PAGE_SIZE = 24;
const SKELETON_COUNT = 12;

const SORT_OPTIONS = [
  { key: "newest", label: "الأحدث" },
  { key: "trending", label: "الرائجة" },
  { key: "oldest", label: "الأقدم" },
  { key: "playlists", label: "قوائم التشغيل" },
];

const toVideoCardProps = (v) => ({
  id: v.id,
  title_ar: v.title,
  description_ar: "",
  thumbnail_url: v.thumbnail,
  video_url: `https://www.youtube.com/watch?v=${v.id}`,
  duration: v.duration,
  view_count: v.viewCount,
  publish_date: v.publishedAt,
});

const matchesQuery = (title = "", query) => title.toLowerCase().includes(query);

const SkeletonGrid = ({ count = SKELETON_COUNT }) => (
  <div className="videos-grid">
    {Array.from({ length: count }).map((_, i) => (
      <div className="video-card-skeleton" key={i} aria-hidden="true">
        <div className="skeleton-thumb"></div>
        <div className="skeleton-line skeleton-line-title"></div>
        <div className="skeleton-line skeleton-line-meta"></div>
      </div>
    ))}
  </div>
);

const ProgramsLibrary = () => {
  // null = still loading (never show stale/fake videos while waiting)
  const [videos, setVideos] = useState(null);
  const [catalogFullyLoaded, setCatalogFullyLoaded] = useState(false);
  const [sortKey, setSortKey] = useState("newest");
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [query, setQuery] = useState("");

  const [playlists, setPlaylists] = useState(null);
  const [openPlaylist, setOpenPlaylist] = useState(null);
  const [playlistVideos, setPlaylistVideos] = useState(null);
  const [playlistVisibleCount, setPlaylistVisibleCount] = useState(PAGE_SIZE);
  const openPlaylistIdRef = useRef(null);

  // Filter row scrolls sideways on small screens; arrows hint there's more.
  const filtersRef = useRef(null);
  const [canScrollStart, setCanScrollStart] = useState(false);
  const [canScrollEnd, setCanScrollEnd] = useState(false);

  const updateFilterArrows = useCallback(() => {
    const el = filtersRef.current;
    if (!el) return;
    // RTL: scrollLeft is 0 at the start and goes negative toward the end
    const scrolled = Math.abs(el.scrollLeft);
    const maxScroll = el.scrollWidth - el.clientWidth;
    setCanScrollStart(scrolled > 4);
    setCanScrollEnd(maxScroll - scrolled > 4);
  }, []);

  useEffect(() => {
    updateFilterArrows();
    window.addEventListener("resize", updateFilterArrows);
    return () => window.removeEventListener("resize", updateFilterArrows);
  }, [updateFilterArrows]);

  const scrollFilters = (direction) => {
    const el = filtersRef.current;
    if (!el) return;
    el.scrollBy({ left: direction * el.clientWidth * 0.6, behavior: "smooth" });
  };

  useEffect(() => {
    let cancelled = false;
    // onProgress shows real videos as each page arrives instead of making
    // people wait for the full ~1200-video catalog before seeing anything.
    fetchAllChannelVideos({
      onProgress: (partial) => {
        if (!cancelled) setVideos(partial);
      },
    }).then((data) => {
      if (cancelled) return;
      setVideos(data);
      setCatalogFullyLoaded(true);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (sortKey !== "playlists" || playlists !== null) return;
    let cancelled = false;
    fetchChannelPlaylists().then((data) => {
      if (!cancelled) setPlaylists(data);
    });
    return () => {
      cancelled = true;
    };
  }, [sortKey, playlists]);

  const normalizedQuery = query.trim().toLowerCase();

  const sortedVideos = useMemo(() => {
    if (!videos) return [];
    const list = [...videos];
    if (sortKey === "newest") {
      list.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    } else if (sortKey === "oldest") {
      list.sort((a, b) => new Date(a.publishedAt) - new Date(b.publishedAt));
    } else if (sortKey === "trending") {
      list.sort((a, b) => b.viewCount - a.viewCount);
    }
    return list;
  }, [videos, sortKey]);

  const filteredVideos = useMemo(() => {
    if (!normalizedQuery) return sortedVideos;
    return sortedVideos.filter((v) => matchesQuery(v.title, normalizedQuery));
  }, [sortedVideos, normalizedQuery]);

  const filteredPlaylists = useMemo(() => {
    if (!playlists) return [];
    if (!normalizedQuery) return playlists;
    return playlists.filter((p) => matchesQuery(p.title, normalizedQuery));
  }, [playlists, normalizedQuery]);

  const filteredPlaylistVideos = useMemo(() => {
    const list = playlistVideos || [];
    if (!normalizedQuery) return list;
    return list.filter((v) => matchesQuery(v.title, normalizedQuery));
  }, [playlistVideos, normalizedQuery]);

  const visibleVideos = filteredVideos.slice(0, visibleCount);
  const hasMore = visibleCount < filteredVideos.length;

  const visiblePlaylistVideos = filteredPlaylistVideos.slice(0, playlistVisibleCount);
  const hasMorePlaylistVideos = playlistVisibleCount < filteredPlaylistVideos.length;

  const handleSortChange = (key) => {
    if (key === sortKey) return;
    setSortKey(key);
    setVisibleCount(PAGE_SIZE);
    openPlaylistIdRef.current = null;
    setOpenPlaylist(null);
    setPlaylistVideos(null);
  };

  const handleQueryChange = (value) => {
    setQuery(value);
    setVisibleCount(PAGE_SIZE);
    setPlaylistVisibleCount(PAGE_SIZE);
  };

  const handleOpenPlaylist = (playlist) => {
    setOpenPlaylist(playlist);
    setPlaylistVideos(null);
    setPlaylistVisibleCount(PAGE_SIZE);
    openPlaylistIdRef.current = playlist.id;
    fetchPlaylistVideos(playlist.id).then((data) => {
      // Ignore a late answer for a playlist the user already left.
      if (openPlaylistIdRef.current === playlist.id) setPlaylistVideos(data);
    });
  };

  const handleBackToPlaylists = () => {
    openPlaylistIdRef.current = null;
    setOpenPlaylist(null);
    setPlaylistVideos(null);
  };

  return (
    <div className="videos-page library-page">
      <div className="page-container">
        <h1 className="section-title">
          <span className="title-bar"></span>مكتبة البرامج
        </h1>

        <div className="library-toolbar">
          <div className="library-filters-wrap">
            {canScrollStart && (
              <button
                type="button"
                className="library-filters-arrow start"
                aria-label="السابق"
                onClick={() => scrollFilters(1)}
              >
                <i className="fas fa-chevron-right"></i>
              </button>
            )}

            <div className="library-filters" ref={filtersRef} onScroll={updateFilterArrows}>
              {SORT_OPTIONS.map((opt) => (
                <button
                  key={opt.key}
                  type="button"
                  className={`library-filter-btn ${sortKey === opt.key ? "active" : ""}`}
                  onClick={(e) => {
                    handleSortChange(opt.key);
                    e.currentTarget.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" });
                  }}
                >
                  {opt.label}
                </button>
              ))}
            </div>

            {canScrollEnd && (
              <button
                type="button"
                className="library-filters-arrow end"
                aria-label="التالي"
                onClick={() => scrollFilters(-1)}
              >
                <i className="fas fa-chevron-left"></i>
              </button>
            )}
          </div>

          <div className="library-search">
            <i className="fas fa-search"></i>
            <input
              type="text"
              value={query}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder="ابحث عن فيديو..."
            />
          </div>
        </div>

        {sortKey === "playlists" ? (
          openPlaylist ? (
            <>
              <button type="button" className="library-back-btn" onClick={handleBackToPlaylists}>
                <i className="fas fa-arrow-right"></i> رجوع لقوائم التشغيل
              </button>

              {playlistVideos === null ? (
                <SkeletonGrid count={8} />
              ) : playlistVideos.length === 0 ? (
                <p className="library-empty">لا توجد فيديوهات في قائمة التشغيل هذه.</p>
              ) : filteredPlaylistVideos.length === 0 ? (
                <p className="library-empty">لا توجد نتائج مطابقة لبحثك في هذه القائمة.</p>
              ) : (
                <>
                  <div className="videos-grid">
                    {visiblePlaylistVideos.map((v) => (
                      <VideoCard key={v.id} video={toVideoCardProps(v)} />
                    ))}
                  </div>

                  {hasMorePlaylistVideos && (
                    <div className="library-load-more">
                      <button
                        type="button"
                        onClick={() => setPlaylistVisibleCount((c) => c + PAGE_SIZE)}
                      >
                        تحميل المزيد
                      </button>
                    </div>
                  )}
                </>
              )}
            </>
          ) : playlists === null ? (
            <SkeletonGrid count={8} />
          ) : playlists.length === 0 ? (
            <p className="library-empty">تعذر تحميل قوائم التشغيل الآن، حاول مرة أخرى لاحقًا.</p>
          ) : filteredPlaylists.length === 0 ? (
            <p className="library-empty">لا توجد نتائج مطابقة لبحثك.</p>
          ) : (
            <div className="videos-grid">
              {filteredPlaylists.map((p) => (
                <div
                  className="video-card playlist-card"
                  key={p.id}
                  role="button"
                  tabIndex={0}
                  onClick={() => handleOpenPlaylist(p)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      handleOpenPlaylist(p);
                    }
                  }}
                >
                  <div className="video-thumb">
                    <img src={p.thumbnail} alt={p.title} />
                    <div className="video-duration">
                      <i className="fas fa-list"></i> {p.itemCount} فيديو
                    </div>
                  </div>
                  <div className="video-content">
                    <h3 className="video-title">{p.title}</h3>
                  </div>
                </div>
              ))}
            </div>
          )
        ) : videos === null ? (
          <SkeletonGrid />
        ) : videos.length === 0 ? (
          <p className="library-empty">تعذر تحميل الفيديوهات الآن، حاول مرة أخرى لاحقًا.</p>
        ) : filteredVideos.length === 0 ? (
          <p className="library-empty">لا توجد نتائج مطابقة لبحثك.</p>
        ) : (
          <>
            <div className="videos-grid">
              {visibleVideos.map((v) => (
                <VideoCard key={v.id} video={toVideoCardProps(v)} />
              ))}
            </div>

            {!catalogFullyLoaded && (
              <p className="library-loading-more">
                <i className="fas fa-spinner fa-spin"></i> جاري تحميل المزيد من الفيديوهات...
              </p>
            )}

            {hasMore && (
              <div className="library-load-more">
                <button type="button" onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}>
                  تحميل المزيد
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ProgramsLibrary;
