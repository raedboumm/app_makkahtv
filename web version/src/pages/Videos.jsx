import React, { useEffect, useState } from "react";
import VideoCard from "../components/VideoCard";
import "../styles/videos.css";

const VideosPage = () => {
  const [videos, setVideos] = useState([]);
  const [loading, setLoading] = useState(true);

  // Static videos data
  const staticVideos = [
    {
      id: 1,
      title_ar: "صلاة التراويح من المسجد الحرام",
      description_ar: "صلاة التراويح المباشرة من الحرم المكي الشريف",
      thumbnail_url: "https://i.ytimg.com/vi/lhwurDCEss4/hqdefault.jpg",
      youtube_id: "lhwurDCEss4",
      video_url: "https://www.youtube.com/watch?v=lhwurDCEss4",
      duration: 3420,
      view_count: 1000,
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
      view_count: 900,
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
      view_count: 700,
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
      view_count: 600,
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
      view_count: 4220,
      publish_date: "2024-01-13",
      type_name: "لقاء"
    },
    {
      id: 9,
      title_ar: "تلاوة خاشعة للشيخ السديس",
      description_ar: "تلاوة قرآنية من صلاة التهجد",
      thumbnail_url: "https://i.ytimg.com/vi/ccV974FRPI8/hqdefault.jpg",
      youtube_id: "ccV974FRPI8",
      video_url: "https://www.youtube.com/watch?v=ccV974FRPI8",
      duration: 2280,
      view_count: 3850,
      publish_date: "2024-01-12",
      type_name: "تلاوة"
    },
    {
      id: 10,
      title_ar: "الطواف حول الكعبة",
      description_ar: "مشاهد مباشرة للطواف حول البيت الحرام",
      thumbnail_url: "https://i.ytimg.com/vi/kdZVmYqdN-M/hqdefault.jpg",
      youtube_id: "kdZVmYqdN-M",
      video_url: "https://www.youtube.com/watch?v=kdZVmYqdN-M",
      duration: 1560,
      view_count: 351,
      publish_date: "2024-01-11",
      type_name: "مشاهد"
    },
    {
      id: 11,
      title_ar: "صلاة الفجر من الحرم",
      description_ar: "صلاة الفجر المباشرة من مكة المكرمة",
      thumbnail_url: "https://i.ytimg.com/vi/pVvkKzvWWBQ/hqdefault.jpg",
      youtube_id: "pVvkKzvWWBQ",
      video_url: "https://www.youtube.com/watch?v=pVvkKzvWWBQ",
      duration: 1440,
      view_count: 3220,
      publish_date: "2024-01-10",
      type_name: "صلاة"
    },
    {
      id: 12,
      title_ar: "دروس من الحرم المكي",
      description_ar: "دروس علمية من المسجد الحرام",
      thumbnail_url: "https://i.ytimg.com/vi/TKUcUAecRtI/hqdefault.jpg",
      youtube_id: "TKUcUAecRtI",
      video_url: "https://www.youtube.com/watch?v=TKUcUAecRtI",
      duration: 2040,
      view_count: 2850,
      publish_date: "2024-01-09",
      type_name: "درس"
    }
  ];

  useEffect(() => {
    loadVideos();
  }, []);

  const loadVideos = async () => {
    setLoading(true);
    // Simulate loading delay
    setTimeout(() => {
      setVideos(staticVideos);
      setLoading(false);
    }, 300);
  };

  if (loading) {
    return (
      <div className="loader-page">
        <i className="fas fa-spinner fa-spin"></i>
        <p>جاري التحميل...</p>
      </div>
    );
  }

  return (
    <div className="videos-page">
      <div className="page-container">
        <h1 className="page-title">
          <i className="fas fa-play-circle"></i> الفيديوهات
        </h1>

        <div className="videos-grid">
          {videos.map((video) => (
            <VideoCard key={video.id} video={video} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default VideosPage;
