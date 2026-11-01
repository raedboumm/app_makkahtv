import React, { useEffect, useState } from "react";
import "../styles/trending.css";


const TrendingArticles = ({ limit = 4, period = "week" }) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  // Static trending videos data
  const staticTrendingVideos = [
    {
      id: 1,
      title_ar: "أذكار المساء",
      view_count: 670,
      link:"https://www.youtube.com/watch?v=kM9qMU4b1T4"
    },
    {
      id: 2,
      title_ar:  "أذكار الصباح",
      view_count: 477,
      link :"https://www.youtube.com/watch?v=VcY_TiljhkU"
    },
    {
      id: 3,
      title_ar: "مكة كلها حرم",
      view_count: 166,
      link : "https://www.youtube.com/watch?v=_6TbpUSNWT4"
    },
    {
      id: 4,
      title_ar: "نشيد ( مكة الغراء )",
      view_count: 135,
      link : "https://www.youtube.com/watch?v=Bvnr3Tjbx5k"
    },
    {
      id: 5,
      title_ar: "نشيد ( عهدٌ ومثابة ) ",
      view_count: 89,
      link : "https://www.youtube.com/watch?v=imK8V9aGPjQ"
    },
     {
      id: 6,
      title_ar: "نشيد ( حسنة في الحرم ) ",
      view_count: "66",
      link : "https://www.youtube.com/watch?v=haP2D-3ZHsU"
     }
  ];

  useEffect(() => {
    setLoading(true);
    // Simulate loading delay
    setTimeout(() => {
      setItems(staticTrendingVideos.slice(0, limit));
      setLoading(false);
    }, 300);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [limit, period]);

  return (
    <div className="trending-box">
      <h3 className="trending-title">
        <i className="fa-solid fa-fire"></i> الأكثر مشاهدة
      </h3>

      {loading ? (
        <div className="trending-loading">
          <i className="fa-solid fa-spinner fa-spin"></i>
          <span>جاري التحميل...</span>
        </div>
      ) : (
        <div className="trending-list">
          {items.map((video, idx) => (
            <div key={video.id ?? idx} className="trending-item">
              <span className="rank">{idx + 1}</span>
              <div className="info">
                <a href={video.link} target="_blank" rel="noopener noreferrer" className="title" title={video.title_ar}>
                  {video.title_ar}</a>
                <div className="meta">
                  <i className="fa-regular fa-eye"></i>
                  <span>{video.view_count ?? 0}k</span>
                </div>
              </div>
            </div>
          ))}

          {items.length === 0 && !loading && (
            <div className="trending-empty">لا توجد عناصر حالياً.</div>
          )}
        </div>
      )}
    </div>
  );
};

export default TrendingArticles;
