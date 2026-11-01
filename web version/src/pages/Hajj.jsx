import React, { useEffect, useState } from "react";
import ArticleCard from "../components/ArticleCard";
import VideoCard from "../components/VideoCard";
import "../styles/hajj.css"; // ✅ New CSS file

const HajjPage = () => {
    const [articles, setArticles] = useState([]);
    const [videos, setVideos] = useState([]);
    const [loading, setLoading] = useState(true);

    // Static Hajj & Umrah articles
    const staticHajjArticles = [
        {
            id: 1,
            title_ar: "مناسك الحج خطوة بخطوة",
            summary_ar: "دليل شامل لجميع مناسك الحج من البداية حتى النهاية",
            image_url: "https://i.ytimg.com/vi/lhwurDCEss4/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-15",
            view_count: 178
        },
        {
            id: 2,
            title_ar: "أحكام العمرة وشروطها",
            summary_ar: "شرح تفصيلي لأحكام وشروط العمرة",
            image_url: "https://i.ytimg.com/vi/vDs_ab_J96I/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-14",
            view_count: 1450
        },
        {
            id: 3,
            title_ar: "فضائل الحج والعمرة",
            summary_ar: "الأحاديث النبوية في فضل الحج والعمرة",
            image_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-13",
            view_count: 1140
        },
        {
            id: 4,
            title_ar: "الأخطاء الشائعة في الحج",
            summary_ar: "تعرف على الأخطاء الشائعة التي يقع فيها الحجاج وكيفية تجنبها",
            image_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-12",
            view_count: 980
        },
        {
            id: 5,
            title_ar: "الإحرام وأنواعه",
            summary_ar: "شرح أنواع الإحرام وأحكامه",
            image_url: "https://i.ytimg.com/vi/WIZ8I4pxqQA/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-11",
            view_count: 870
        },
        {
            id: 6,
            title_ar: "يوم عرفة وفضله",
            summary_ar: "فضل يوم عرفة وأعمال هذا اليوم المبارك",
            image_url: "https://i.ytimg.com/vi/dGY1RVobDPU/hqdefault.jpg",
            category_name: "حج وعمرة",
            publish_date: "2024-01-10",
            view_count: 700
        }
    ];

    // Static Hajj & Umrah videos
    const staticHajjVideos = [
        {
            id: 1,
            title_ar: "مناسك الحج - شرح مفصل",
            description_ar: "شرح تفصيلي ومصور لجميع مناسك الحج",
            thumbnail_url: "https://i.ytimg.com/vi/lhwurDCEss4/hqdefault.jpg",
            youtube_id: "lhwurDCEss4",
            video_url: "https://www.youtube.com/watch?v=pALGQ4AK30Y&t=1s",
            duration: 2880,
            view_count: 150,
            publish_date: "2024-01-18",
            type_name: "تعليمي"
        },
        {
            id: 2,
            title_ar: "طواف الإفاضة",
            description_ar: "شرح طواف الإفاضة وأحكامه",
            thumbnail_url: "https://i.ytimg.com/vi/vDs_ab_J96I/hqdefault.jpg",
            youtube_id: "vDs_ab_J96I",
            video_url: "https://www.youtube.com/watch?v=PJIQHmJMCmI",
            duration: 1740,
            view_count: 120,
            publish_date: "2024-01-17",
            type_name: "مناسك"
        },
        {
            id: 3,
            title_ar: "السعي بين الصفا والمروة",
            description_ar: "كيفية السعي بين الصفا والمروة",
            thumbnail_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg",
            youtube_id: "QlasJcax37k",
            video_url: "https://www.youtube.com/watch?v=QlasJcax37k",
            duration: 1620,
            view_count: 9510,
            publish_date: "2024-01-16",
            type_name: "مناسك"
        },
        {
            id: 4,
            title_ar: "رمي الجمرات",
            description_ar: "شرح مفصل لرمي الجمرات وأحكامه",
            thumbnail_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg",
            youtube_id: "hE9VDhUDT-4",
            video_url: "https://www.youtube.com/watch?v=icJfRBOip0U",
            duration: 1440,
            view_count: 88,
            publish_date: "2024-01-15",
            type_name: "مناسك"
        }
    ];

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        // Simulate loading delay
        setTimeout(() => {
            setArticles(staticHajjArticles);
            setVideos(staticHajjVideos);
            setLoading(false);
        }, 300);
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <i className="fas fa-spinner fa-spin text-4xl text-makkah-gold"></i>
            </div>
        );
    }

    return (
        <div className="bg-white min-h-screen">
            {/* ✅ Hero Section */}
            <div className="hajj-hero hero-gradient text-white py-16 mb-12">
                <div className="container mx-auto px-4 text-center">
                    <i className="fas fa-kaaba text-6xl text-makkah-gold mb-4"></i>
                    <h1 className="text-4xl font-bold mb-4">الحج والعمرة</h1>
                    <p className="text-xl text-gray-300">
                        كل ما يتعلق بالحج والعمرة من أخبار وإرشادات ومناسك
                    </p>
                </div>
            </div>

            {/* ✅ Content Section */}
            <div className="container mx-auto px-4 pb-12">
                {/* Articles */}
                <h2 className="section-title flex items-center gap-2">
                    <div className="w-1 h-8 bg-makkah-gold"></div>
                    أخبار الحج والعمرة
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
                    {articles.map((article) => (
                        <ArticleCard key={article.id} article={article} />
                    ))}
                </div>

                {/* Videos */}
                <h2 className="section-title flex items-center gap-2">
                    <div className="w-1 h-8 bg-makkah-gold"></div>
                    فيديوهات الحج والعمرة
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    {videos.map((video) => (
                        <VideoCard key={video.id} video={video} />
                    ))}
                </div>
            </div>
        </div>
    );
};

export default HajjPage;
