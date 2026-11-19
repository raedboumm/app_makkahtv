import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import VideoCard from "../components/VideoCard";
import VideoSkeletonGrid from "../components/VideoSkeletonGrid";
import "../styles/videos.css";
import "../styles/library.css";
import "../styles/ProgramEpisodes.css";
import { fetchAllChannelVideos, toVideoCardProps } from "../services/youtube";
import useRandomOrder from "../hooks/useRandomOrder";

const PAGE_SIZE = 24;

const SORT_OPTIONS = [
  { key: "random", label: "عشوائي" },
  { key: "newest", label: "الأحدث" },
  { key: "trending", label: "الرائجة" },
  { key: "oldest", label: "الأقدم" },
];

const matchesQuery = (title = "", query) => title.toLowerCase().includes(query);

const ProgramsLibrary = () => {
  // null = still loading (never show stale/fake videos while waiting)
  const [videos, setVideos] = useState(null);
  const [catalogFullyLoaded, setCatalogFullyLoaded] = useState(false);
  const [sortKey, setSortKey] = useState("random");
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [query, setQuery] = useState("");

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

  const normalizedQuery = query.trim().toLowerCase();

  const randomVideos = useRandomOrder(videos);

  const sortedVideos = useMemo(() => {
    if (!videos) return [];
    if (sortKey === "random") return randomVideos;
    const list = [...videos];
    if (sortKey === "newest") {
      list.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    } else if (sortKey === "oldest") {
      list.sort((a, b) => new Date(a.publishedAt) - new Date(b.publishedAt));
    } else if (sortKey === "trending") {
      list.sort((a, b) => b.viewCount - a.viewCount);
    }
    return list;
  }, [videos, randomVideos, sortKey]);

  const filteredVideos = useMemo(() => {
    if (!normalizedQuery) return sortedVideos;
    return sortedVideos.filter((v) => matchesQuery(v.title, normalizedQuery));
  }, [sortedVideos, normalizedQuery]);

  const visibleVideos = filteredVideos.slice(0, visibleCount);
  const hasMore = visibleCount < filteredVideos.length;

  const handleSortChange = (key) => {
    if (key === sortKey) return;
    setSortKey(key);
    setVisibleCount(PAGE_SIZE);
  };

  const handleQueryChange = (value) => {
    setQuery(value);
    setVisibleCount(PAGE_SIZE);
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

        {videos === null ? (
          <VideoSkeletonGrid />
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
