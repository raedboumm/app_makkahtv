import React, { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import VideoCard from "./VideoCard";
import VideoSkeletonGrid from "./VideoSkeletonGrid";
import "../styles/videos.css";
import "../styles/library.css";
import "../styles/ProgramEpisodes.css";
import {
  fetchAllChannelVideos,
  fetchLatestChannelVideos,
  toVideoCardProps,
} from "../services/youtube";
import useRandomOrder from "../hooks/useRandomOrder";

const CARD_COUNT = 3;

const FILTERS = [
  { key: "random", label: "عشوائي" },
  { key: "newest", label: "الأحدث" },
  { key: "trending", label: "الرائجة" },
  { key: "oldest", label: "الأقدم" },
];

// Homepage preview of "مكتبة البرامج". عشوائي and الأحدث need only one API page,
// so the full ~1200-video catalog is fetched only if a visitor picks another
// filter: the homepage gets far more cold visits than /library and walking the
// whole catalog for each would burn through the YouTube API quota.
const HomeLibrarySection = () => {
  const [filter, setFilter] = useState("random");
  const [latest, setLatest] = useState(null);
  const [catalog, setCatalog] = useState(null);

  useEffect(() => {
    let cancelled = false;
    fetchLatestChannelVideos().then((data) => {
      if (!cancelled) setLatest(data);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const needsCatalog = filter === "trending" || filter === "oldest";
  const randomVideos = useRandomOrder(latest);

  useEffect(() => {
    if (!needsCatalog || catalog !== null) return;
    let cancelled = false;
    fetchAllChannelVideos({
      onProgress: (partial) => {
        if (!cancelled) setCatalog(partial);
      },
    }).then((data) => {
      if (!cancelled) setCatalog(data);
    });
    return () => {
      cancelled = true;
    };
    // Only the first switch away from الأحدث starts the fetch; progress
    // updates to `catalog` must not cancel it.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [needsCatalog]);

  const source = needsCatalog ? catalog : latest;

  const visibleVideos = useMemo(() => {
    if (!source) return [];
    if (filter === "random") return randomVideos.slice(0, CARD_COUNT);
    const list = [...source];
    if (filter === "newest") {
      list.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    } else if (filter === "oldest") {
      list.sort((a, b) => new Date(a.publishedAt) - new Date(b.publishedAt));
    } else {
      list.sort((a, b) => b.viewCount - a.viewCount);
    }
    return list.slice(0, CARD_COUNT);
  }, [source, randomVideos, filter]);

  return (
    <div className="home-section">
      <div className="home-section-header">
        <h2 className="section-title">
          <span className="title-bar"></span> مكتبة البرامج
        </h2>
        <Link to="/library" className="home-section-more">
          عرض الكل <i className="fas fa-chevron-left"></i>
        </Link>
      </div>

      <div className="library-filters home-section-filters">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            type="button"
            className={`library-filter-btn ${filter === f.key ? "active" : ""}`}
            onClick={() => setFilter(f.key)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {source === null ? (
        <VideoSkeletonGrid count={CARD_COUNT} />
      ) : visibleVideos.length === 0 ? (
        <p className="library-empty">تعذر تحميل الفيديوهات الآن، حاول مرة أخرى لاحقًا.</p>
      ) : (
        <div className="videos-grid">
          {visibleVideos.map((v) => (
            <VideoCard key={v.id} video={toVideoCardProps(v)} />
          ))}
        </div>
      )}
    </div>
  );
};

export default HomeLibrarySection;
