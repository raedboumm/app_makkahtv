import React from "react";

const VideoSkeletonGrid = ({ count = 12 }) => (
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

export default VideoSkeletonGrid;
