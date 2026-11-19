import React, { useEffect, useMemo, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import VideoCard from "../components/VideoCard";
import PlaylistCard from "../components/PlaylistCard";
import VideoSkeletonGrid from "../components/VideoSkeletonGrid";
import "../styles/videos.css";
import "../styles/library.css";
import "../styles/ProgramEpisodes.css";
import { fetchChannelPlaylists, fetchPlaylistVideos, toVideoCardProps } from "../services/youtube";
import useRandomOrder from "../hooks/useRandomOrder";

const PAGE_SIZE = 24;

const matchesQuery = (title = "", query) => title.toLowerCase().includes(query);

// "سلاسل البرامج": the channel's YouTube playlists, with drill-down into one.
const ProgramSeries = () => {
  // null = still loading
  const [playlists, setPlaylists] = useState(null);
  const [openPlaylist, setOpenPlaylist] = useState(null);
  const [playlistVideos, setPlaylistVideos] = useState(null);
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [query, setQuery] = useState("");
  const openPlaylistIdRef = useRef(null);
  const location = useLocation();

  useEffect(() => {
    let cancelled = false;
    fetchChannelPlaylists().then((data) => {
      if (!cancelled) setPlaylists(data);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  // A series clicked on the homepage arrives here already chosen.
  useEffect(() => {
    if (location.state?.playlist) handleOpenPlaylist(location.state.playlist);
  }, [location.state]);

  const normalizedQuery = query.trim().toLowerCase();

  const randomPlaylists = useRandomOrder(playlists);

  const filteredPlaylists = useMemo(() => {
    if (!normalizedQuery) return randomPlaylists;
    return randomPlaylists.filter((p) => matchesQuery(p.title, normalizedQuery));
  }, [randomPlaylists, normalizedQuery]);

  const filteredVideos = useMemo(() => {
    const list = playlistVideos || [];
    if (!normalizedQuery) return list;
    return list.filter((v) => matchesQuery(v.title, normalizedQuery));
  }, [playlistVideos, normalizedQuery]);

  const visibleVideos = filteredVideos.slice(0, visibleCount);
  const hasMore = visibleCount < filteredVideos.length;

  const handleQueryChange = (value) => {
    setQuery(value);
    setVisibleCount(PAGE_SIZE);
  };

  const handleOpenPlaylist = (playlist) => {
    setOpenPlaylist(playlist);
    setPlaylistVideos(null);
    setVisibleCount(PAGE_SIZE);
    openPlaylistIdRef.current = playlist.id;
    fetchPlaylistVideos(playlist.id).then((data) => {
      // Ignore a late answer for a playlist the user already left.
      if (openPlaylistIdRef.current === playlist.id) setPlaylistVideos(data);
    });
  };

  const handleBack = () => {
    openPlaylistIdRef.current = null;
    setOpenPlaylist(null);
    setPlaylistVideos(null);
  };

  return (
    <div className="videos-page library-page">
      <div className="page-container">
        <h1 className="section-title">
          <span className="title-bar"></span>سلاسل البرامج
        </h1>

        <div className="library-toolbar">
          <div className="library-search">
            <i className="fas fa-search"></i>
            <input
              type="text"
              value={query}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder={openPlaylist ? "ابحث عن فيديو..." : "ابحث عن سلسلة..."}
            />
          </div>
        </div>

        {openPlaylist ? (
          <>
            <button type="button" className="library-back-btn" onClick={handleBack}>
              <i className="fas fa-arrow-right"></i> رجوع لسلاسل البرامج
            </button>

            {playlistVideos === null ? (
              <VideoSkeletonGrid count={8} />
            ) : playlistVideos.length === 0 ? (
              <p className="library-empty">لا توجد فيديوهات في هذه السلسلة.</p>
            ) : filteredVideos.length === 0 ? (
              <p className="library-empty">لا توجد نتائج مطابقة لبحثك في هذه السلسلة.</p>
            ) : (
              <>
                <div className="videos-grid">
                  {visibleVideos.map((v) => (
                    <VideoCard key={v.id} video={toVideoCardProps(v)} />
                  ))}
                </div>

                {hasMore && (
                  <div className="library-load-more">
                    <button type="button" onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}>
                      تحميل المزيد
                    </button>
                  </div>
                )}
              </>
            )}
          </>
        ) : playlists === null ? (
          <VideoSkeletonGrid count={8} />
        ) : playlists.length === 0 ? (
          <p className="library-empty">تعذر تحميل سلاسل البرامج الآن، حاول مرة أخرى لاحقًا.</p>
        ) : filteredPlaylists.length === 0 ? (
          <p className="library-empty">لا توجد نتائج مطابقة لبحثك.</p>
        ) : (
          <div className="videos-grid">
            {filteredPlaylists.map((p) => (
              <PlaylistCard key={p.id} playlist={p} onOpen={handleOpenPlaylist} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProgramSeries;
