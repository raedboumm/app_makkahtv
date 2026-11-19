import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import PlaylistCard from "./PlaylistCard";
import VideoSkeletonGrid from "./VideoSkeletonGrid";
import "../styles/videos.css";
import "../styles/library.css";
import "../styles/ProgramEpisodes.css";
import { fetchChannelPlaylists } from "../services/youtube";
import useRandomOrder from "../hooks/useRandomOrder";

const CARD_COUNT = 3;

// Homepage preview of "سلاسل البرامج" (the channel's YouTube playlists).
const HomeSeriesSection = () => {
  const [playlists, setPlaylists] = useState(null);
  const navigate = useNavigate();
  const randomPlaylists = useRandomOrder(playlists);

  useEffect(() => {
    let cancelled = false;
    fetchChannelPlaylists().then((data) => {
      if (!cancelled) setPlaylists(data);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="home-section">
      <div className="home-section-header">
        <h2 className="section-title">
          <span className="title-bar"></span> سلاسل البرامج
        </h2>
        <Link to="/series" className="home-section-more">
          عرض الكل <i className="fas fa-chevron-left"></i>
        </Link>
      </div>

      {playlists === null ? (
        <VideoSkeletonGrid count={CARD_COUNT} />
      ) : playlists.length === 0 ? (
        <p className="library-empty">تعذر تحميل سلاسل البرامج الآن، حاول مرة أخرى لاحقًا.</p>
      ) : (
        <div className="videos-grid">
          {randomPlaylists.slice(0, CARD_COUNT).map((p) => (
            <PlaylistCard
              key={p.id}
              playlist={p}
              onOpen={(playlist) => navigate("/series", { state: { playlist } })}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default HomeSeriesSection;
