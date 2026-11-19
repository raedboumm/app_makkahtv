import React from "react";

const PlaylistCard = ({ playlist, onOpen }) => (
  <div
    className="video-card playlist-card"
    role="button"
    tabIndex={0}
    onClick={() => onOpen(playlist)}
    onKeyDown={(e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        onOpen(playlist);
      }
    }}
  >
    <div className="video-thumb">
      <img src={playlist.thumbnail} alt={playlist.title} />
      <div className="video-duration">
        <i className="fas fa-list"></i> {playlist.itemCount} فيديو
      </div>
    </div>
    <div className="video-content">
      <h3 className="video-title">{playlist.title}</h3>
    </div>
  </div>
);

export default PlaylistCard;
