import React, { useEffect, useState } from "react";
import ArticleCard from "../components/ArticleCard";
import VideoCard from "../components/VideoCard";
import PrayerTimes from "../components/PrayerTimes";
import TrendingArticles from "../components/TrendingArticles";
import "../styles/home.css";
import ChannelInfo from "../components/ChannelInfo";
import { extractYouTubeId, fetchTopChannelVideos, fetchViewCounts } from "../services/youtube";
import { LiveStreamSlot } from "../context/LiveStream";
import { scrollToSection } from "../services/scrollToSection";

import HomeLibrarySection from "../components/HomeLibrarySection";
import HomeSeriesSection from "../components/HomeSeriesSection";





const Home = () => {
  const [featuredArticles, setFeaturedArticles] = useState([]);
  const [articles, setArticles] = useState([]);
  const [videos, setVideos] = useState([]);
  const [videosPage, setVideosPage] = useState(1);
  const [videosTotalPages, setVideosTotalPages] = useState(1);
  const [mostViewed, setMostViewed] = useState([]);
  const [selectedVideo, setSelectedVideo] = useState(null);
  const [loading, setLoading] = useState(true);

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

  // Static featured articles
  const staticFeaturedArticles = [
    {
      id: 1,
      title_ar: "البث المباشر من المسجد الحرام",
      summary_ar: "متابعة مباشرة للصلوات والشعائر من الحرم المكي الشريف",
      image_url: "https://makkahlive.net/images/MakkahLiveCover.jpg",
      category_name: "بث مباشر",
      publish_date: "2024-01-15",
      view_count: 2450,
      featured: true
    },
    {
      id: 2,
      title_ar: "افتتاح مشروع توسعة المسجد الحرام",
      summary_ar: "أعلنت الرئاسة العامة لشؤون المسجد الحرام عن افتتاح المرحلة الأولى من التوسعة",
      image_url: "https://i.ytimg.com/vi/lhwurDCEss4/hqdefault.jpg",
      category_name: "بث مباشر",
      publish_date: "2024-01-14",
      view_count: 180,
      featured: true
    },

  ];

  // Static articles
  const staticArticles = [
    {
      id: 4,
      title_ar: "برامج توعوية للحجاج بعدة لغات",
      summary_ar: "أطلقت وزارة الحج والعمرة برامج توعوية شاملة",
      image_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg",
      category_name: "حج وعمرة",
      publish_date: "2024-01-12",
      view_count: 4500
    },
    {
      id: 5,
      title_ar: "تطوير خدمات الإفتاء في الحرم",
      summary_ar: "تم تطوير مركز الإفتاء في المسجد الحرام",
      image_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg",
      category_name: "أخبار",
      publish_date: "2024-01-11",
      view_count: 380
    }
  ];

  // Static videos
  const staticVideos = [
    {
      id: 1,
      title_ar: "صلاة التراويح من المسجد الحرام",
      description_ar: "صلاة التراويح المباشرة من الحرم المكي",
      thumbnail_url: "https://i.ytimg.com/vi/lhwurDCEss4/hqdefault.jpg",
      youtube_id: "lhwurDCEss4",
      video_url: "https://www.youtube.com/watch?v=lhwurDCEss4",
      duration: 3420,
      view_count: 1250,
      publish_date: "2024-01-20",
      type_name: "صلاة"
    },
    {
      id: 2,
      title_ar: "خطبة الجمعة من مكة المكرمة",
      description_ar: "خطبة الجمعة المباشرة من المسجد الحرام",
      thumbnail_url: "https://i.ytimg.com/vi/vDs_ab_J96I/hqdefault.jpg",
      youtube_id: "vDs_ab_J96I",
      video_url: "https://www.youtube.com/watch?v=vDs_ab_J96I",
      duration: 2640,
      view_count: 980,
      publish_date: "2024-01-19",
      type_name: "خطبة"
    },
    {
      id: 3,
      title_ar: "برنامج نور القرآن",
      description_ar: "برنامج يومي لتفسير القرآن الكريم",
      thumbnail_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg",
      youtube_id: "QlasJcax37k",
      video_url: "https://www.youtube.com/watch?v=QlasJcax37k",
      duration: 1800,
      view_count: 870,
      publish_date: "2024-01-18",
      type_name: "برنامج"
    },
    {
      id: 4,
      title_ar: "في رحاب الحرم",
      description_ar: "جولات حصرية داخل المسجد الحرام",
      thumbnail_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg",
      youtube_id: "hE9VDhUDT-4",
      video_url: "https://www.youtube.com/watch?v=hE9VDhUDT-4",
      duration: 2100,
      view_count: 760,
      publish_date: "2024-01-17",
      type_name: "برنامج"
    },
    {
      id: 5,
      title_ar: "مناسك الحج والعمرة",
      description_ar: "شرح تفصيلي لمناسك الحج والعمرة",
      thumbnail_url: "https://i.ytimg.com/vi/WIZ8I4pxqQA/hqdefault.jpg",
      youtube_id: "WIZ8I4pxqQA",
      video_url: "https://www.youtube.com/watch?v=WIZ8I4pxqQA",
      duration: 2520,
      view_count: 650,
      publish_date: "2024-01-16",
      type_name: "تعليمي"
    },
    {
      id: 6,
      title_ar: "أذان الفجر من الحرم",
      description_ar: "أذان الفجر المباشر من المسجد الحرام",
      thumbnail_url: "https://i.ytimg.com/vi/dGY1RVobDPU/hqdefault.jpg",
      youtube_id: "dGY1RVobDPU",
      video_url: "https://www.youtube.com/watch?v=dGY1RVobDPU",
      duration: 1320,
      view_count: 540,
      publish_date: "2024-01-15",
      type_name: "أذان"
    },
    {
      id: 7,
      title_ar: "حديث الروح",
      description_ar: "برنامج روحاني يتناول القصص الإيمانية",
      thumbnail_url: "https://i.ytimg.com/vi/qKS9sC3nl_c/hqdefault.jpg",
      youtube_id: "qKS9sC3nl_c",
      video_url: "https://www.youtube.com/watch?v=qKS9sC3nl_c",
      duration: 1680,
      view_count: 480,
      publish_date: "2024-01-14",
      type_name: "برنامج"
    },
    {
      id: 8,
      title_ar: "لقاء مع علماء الأمة",
      description_ar: "حوارات مباشرة مع كبار العلماء",
      thumbnail_url: "https://i.ytimg.com/vi/BOk9o1GpTUo/hqdefault.jpg",
      youtube_id: "BOk9o1GpTUo",
      video_url: "https://www.youtube.com/watch?v=BOk9o1GpTUo",
      duration: 1920,
      view_count: 420,
      publish_date: "2024-01-13",
      type_name: "لقاء"
    }
  ];

  // Fallback for "most viewed", shown only when the channel's real top videos
  // can't be fetched.
  const staticMostViewed = [
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
    const timeoutId = loadData();
    return () => clearTimeout(timeoutId);
  }, []);

  // ✅ "Most viewed" = the channel's real top 7 on YouTube.
  useEffect(() => {
    let cancelled = false;

    fetchTopChannelVideos(7).then((top) => {
      if (cancelled) return;
      setMostViewed(
        top.length > 0
          ? top.map((v) => ({
              id: v.id,
              title_ar: v.title.replace(/\s*\|\s*قناة مكة\s*$/, ""),
              view_count: v.viewCount,
              link: `https://www.youtube.com/watch?v=${v.id}`,
            }))
          : // view_count starts as null (loading skeleton) — the static numbers
            // above were placeholders only, never real, so we never display them.
            staticMostViewed.map((item) => ({ ...item, view_count: null }))
      );
    });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ✅ Fetch real YouTube view counts for the fallback "most viewed" list.
  // view_count stays null (-> skeleton) until the API answers, so the fake
  // static numbers are never shown. Items the API can't resolve become -1
  // (-> "unavailable"), never a wrong/stale number.
  useEffect(() => {
    if (!mostViewed.some((item) => item.view_count === null)) return;

    let cancelled = false;
    const ids = mostViewed.map((item) => extractYouTubeId(item.link));

    fetchViewCounts(ids).then((counts) => {
      if (cancelled) return;
      setMostViewed((prev) =>
        prev.map((item) => {
          const id = extractYouTubeId(item.link);
          return { ...item, view_count: counts[id] != null ? counts[id] : -1 };
        })
      );
    });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mostViewed.length]);

  useEffect(() => {
    const goLive = () => setSelectedVideo(null);
    window.addEventListener("makkah:go-live", goLive);
    return () => window.removeEventListener("makkah:go-live", goLive);
  }, []);

  // Picks up a scroll target left by the header when a nav item (e.g. البث
  // المباشر) was clicked from another page — that section
  // only exists here, so the header navigates home and leaves this for us.
  // Waits for loading to finish since that's when these sections actually
  // render.
  useEffect(() => {
    if (loading) return;

    const raw = sessionStorage.getItem("makkah_pending_scroll");
    if (!raw) return;
    sessionStorage.removeItem("makkah_pending_scroll");

    try {
      const { id, live } = JSON.parse(raw);
      if (live) setSelectedVideo(null);

      scrollToSection(id);
    } catch (e) {}
  }, [loading]);

  const loadData = (page = 1) => {
    setLoading(true);
    // Simulate loading delay
    return setTimeout(() => {
      setFeaturedArticles(staticFeaturedArticles);
      setArticles(staticArticles);
      setVideos(staticVideos);
      setVideosPage(1);
      setVideosTotalPages(1);
      setLoading(false);
    }, 300);
  };

  if (loading) return <p className="loading">جاري التحميل...</p>;

  return (
    <div className="home-wrapper">

      {/* ✅ Featured Hero Section */}
      <section className="hero-gradient" id="live-hero">
        <div className="container">
          <div className="grid hero-grid">
            {featuredArticles.map((article, i) =>
              i === 0 ? (
                selectedVideo ? (
                  <div
                    key="hero-selected-video"
                    role="button"
                    tabIndex={0}
                    aria-label={selectedVideo.title_ar}
                    style={{
                      position: "relative",
                      width: "100%",
                      paddingTop: "56.25%",
                      borderRadius: "12px",
                      overflow: "hidden",
                      background: "#000",
                    }}
                    onKeyDown={(ev) => {
                      if (ev.key === "Enter" || ev.key === " ") {
                        ev.preventDefault();
                        window.open(selectedVideo.link, "_blank");
                      }
                    }}
                    onClick={() => {
                      window.open(selectedVideo.link, "_blank");
                    }}
                  >
                    <iframe
                      src={getYouTubeEmbed(selectedVideo.link)}
                      title={selectedVideo.title_ar}
                      frameBorder="0"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowFullScreen
                      style={{
                        position: "absolute",
                        inset: 0,
                        width: "100%",
                        height: "100%",
                      }}
                    />
                  </div>
                ) : (
                  // ✅ Replace FIRST featured article ONLY with YouTube Live
<div
  key="yt-live"
  style={{
    position: "relative",
    width: "100%",
    paddingTop: "56.25%",
    borderRadius: "12px",
    overflow: "hidden",
    background: "#000",
  }}
>
 
 
<LiveStreamSlot
  style={{
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
  }}
/>

  <div
    style={{
      position: "absolute",
      top: 12,
      right: 12,
      padding: "6px 10px",
      borderRadius: 999,
      background: "rgba(255,0,0,0.9)",
      color: "#fff",
      fontSize: 12,
      fontWeight: 700,
      zIndex: 2,
    }}
  >
    LIVE
  </div>
</div>
                )
              ) : (
                <ArticleCard key={article.id} index={i} mostViewed={mostViewed} article={article} featured onMostViewedClick={setSelectedVideo} />
              ))}
          </div>
        </div>
       
      </section>
      {/* ✅ Program library + Sidebar */}
      <section id="library-section" className="news-wrapper" >
        <div className="container news-layout">
          {/* Main News */}
          <HomeLibrarySection />

          

          {/* Sidebar */}
          <aside className="sidebar">


            {/* ✅ Prayer Times */}
            
            <ChannelInfo />  
            

          </aside>
        </div>
      </section>
 
      {/* ✅ Program series + Sidebar */}
      <section id="series-section" className="episodes-wrapper">
        <div className="container news-layout">
          <HomeSeriesSection />
 {/* Sidebar */}
          <aside className="sidebar">

 
            <PrayerTimes />
            

          </aside>
        </div>
      </section>
    </div>
  );
};

export default Home;
