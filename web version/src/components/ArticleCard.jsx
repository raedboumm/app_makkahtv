import React from "react";
import { Link } from 'react-router-dom';
import "../styles/articleCard.css";
import logo from "../assets/smallIcon2.png"; // keep this path as you have it
import { formatViewCount } from "../services/youtube";


const ArticleCard = ({ article, featured = false, index, mostViewed = [], onMostViewedClick }) => {
    // Normalize ids so channel-* items link to numeric ids (e.g. channel-2 -> 2)
    const normalizeId = (id) => {
        if (id === null || typeof id === 'undefined') return id;
        const s = String(id);
        const m = s.match(/^channel-(\d+)$/i);
        if (m) return m[1];
        return s;
    };
    const formatDate = (dateStr) => {
        if (!dateStr) return "";
        const date = new Date(dateStr);
        return date.toLocaleDateString("ar-SA");
    };
const getYouTubeId = (url = "") => {
    try {
        const u = new URL(url);

        if (u.hostname.includes("youtu.be")) {
            return u.pathname.slice(1);
        }

        if (u.hostname.includes("youtube.com")) {
            return u.searchParams.get("v");
        }
    } catch (e) {}

    return null;
};

const getYouTubeEmbed = (url = "") => {
    const id = getYouTubeId(url);

    if (!id) return null;

    return `https://www.youtube.com/embed/${id}?autoplay=1&rel=0&modestbranding=1`;
};

const handlePlay = (e, article) => {
    e.preventDefault();

    if (!article?.youtube) return;

    const ytEmbed = getYouTubeEmbed(article.youtube);

    if (ytEmbed) {
        setPlayerType("youtube");
        setPlayerSrc(ytEmbed);
    } else if (/(\.mp4|\.webm|\.ogg)(\?|$)/i.test(article.youtube)) {
        setPlayerType("video");
        setPlayerSrc(article.youtube);
    } else {
        setPlayerType("iframe");
        setPlayerSrc(article.youtube);
    }

    setIsOpen(true);
};

const closePlayer = () => {
    setIsOpen(false);
    setPlayerSrc(null);
    setPlayerType(null);
};
    /* ---------------------------------------
      ✅ IF SECOND CARD → SHOW MOST VIEWED BOX
    ----------------------------------------*/
    // Re-render when the videos cache updates so descriptions appear once available
    const [__videosCacheVersion, setVideosCacheVersion] = React.useState(0);
    const [isOpen, setIsOpen] = React.useState(false);
const [playerSrc, setPlayerSrc] = React.useState(null);
const [playerType, setPlayerType] = React.useState(null);
    React.useEffect(() => {
        const onUpdate = () => setVideosCacheVersion((v) => v + 1);
        if (typeof window !== 'undefined') window.addEventListener('videosCacheUpdated', onUpdate);
        return () => { if (typeof window !== 'undefined') window.removeEventListener('videosCacheUpdated', onUpdate); };
    }, []);

    if (index === 1) {
        return (
            
        
<div className="trending-box">
      <h3 className="trending-title">
        <img className="footer__logo" src={logo} alt="makkah logo" /> الأكثر مشاهدة
      </h3>
       <div className="trending-list">
                {mostViewed.length === 0 && (
                    <p className="text-gray-500 text-sm">لا توجد بيانات الآن...</p>
                )}
        
                {mostViewed.map((item, i) => {
                    const fromCache = (typeof window !== 'undefined' && window.__VIDEOS_BY_ID__) ?
                        (window.__VIDEOS_BY_ID__[item?.id]?.description_ar || window.__VIDEOS_BY_ID__[item?.slug]?.description_ar) : '';
                    const desc = item?.description_ar || item?.summary_ar || fromCache || '—';
                    return (
                        <div className="trending-item" key={item.id || i}>
                            <span className="rank">{i + 1}</span>
                            <div className="info">
                                <button
                                    type="button"
                                    onClick={() => onMostViewedClick?.(item)}
                                    className="most-viewed-item title"
                                    style={{ textDecoration: 'none', background: 'none', border: 'none', padding: 0, color: 'inherit', cursor: 'pointer' }}
                                >
                                    {item.title_ar}
                                </button>
                                <span className="views">
                                    <i className="far fa-eye"></i>{" "}
                                    {item.view_count === null ? (
                                        <span className="views-skeleton" aria-label="جاري تحميل عدد المشاهدات"></span>
                                    ) : item.view_count === -1 ? (
                                        <span className="views-unavailable">غير متاح</span>
                                    ) : (
                                        formatViewCount(item.view_count)
                                    )}
                                </span>
                            </div>
                        </div>
                    )
                })}
                
            </div>
        </div>
        );
    }

    /* ---------------------------------------
      ✅ Featured Card
    ----------------------------------------*/
    if (featured) {
        return (
            <Link to={`/news/${normalizeId(article.id)}`} className="relative overflow-hidden rounded-lg shadow-lg card-hover cursor-pointer bg-white self-start" style={{ textDecoration: 'none' }}>
                <div className="relative h-96">
                    <img src={article.image_url} alt={article.title_ar} className="w-full h-full object-cover" />

                    <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent"></div>

                    {article.is_breaking && (
                        <div className="absolute top-4 right-4">
                            <span className="bg-red-600 text-white px-4 py-1 rounded-full text-sm font-bold breaking-badge">
                                <i className="fas fa-bolt mr-1"></i> أخبار
                            </span>
                        </div>
                    )}

                    <div className="absolute bottom-0 right-0 p-6 z-20 max-w-2xl text-right w-full">
                        {article.category_name && (
                            <span className="inline-block bg-makkah-gold text-makkah-dark px-3 py-1 rounded-full text-sm font-bold mb-3">
                                {article.category_name}
                            </span>
                        )}
                        <h2 className="text-white text-2xl font-bold mb-2">{article.title_ar}</h2>
                        <p className="text-gray-200 mb-3 line-clamp-2">{article.summary_ar}</p>
                        <div className="flex items-center gap-4 text-gray-300 text-sm">
                            <span><i className="far fa-clock mr-1"></i> {formatDate(article.publish_date)}</span>
                            <span><i className="far fa-eye mr-1"></i> {article.view_count} مشاهدة</span>
                        </div>
                    </div>
                </div>
            </Link>
        );
    }

    /* ---------------------------------------
      ✅ NORMAL Article Card
    ----------------------------------------*/
    return (
    <>
        <div
            onClick={(e) => handlePlay(e, article)}
            className="Blkprogram2 bg-white rounded-lg shadow-md overflow-hidden card-hover cursor-pointer"
            style={{ textDecoration: 'none', color: 'inherit' }}
        >
            <div className="relative">
                <img
                    src={article.image_url}
                    alt={article.title_ar}
                    className="w-full h-48 object-cover"
                />

                {article.is_breaking && (
                    <div className="absolute top-2 right-2">
                        <span className="bg-red-600 text-white px-3 py-1 rounded-full text-xs font-bold breaking-small">
                            أخبار
                        </span>
                    </div>
                )}

                <div className="btnplay">
                    <div
                        style={{
                            width: 60,
                            height: 60,
                            borderRadius: "50%",
                            background: "rgba(0,0,0,0.6)",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                        }}
                    >
                        <i
                            className="fas fa-play"
                            style={{
                                color: "#fff",
                                fontSize: 24,
                                marginLeft: 4,
                            }}
                        ></i>
                    </div>
                </div>
            </div>

            <div className="p-4">
                {article.category_name && (
                    <span className="inline-block bg-makkah-gold text-makkah-dark px-2 py-1 rounded text-xs font-bold mb-2">
                        {article.category_name}
                    </span>
                )}

                <h3 className="text-lg font-bold text-gray-800 mb-2 line-clamp-2">
                    {article.title_ar}
                </h3>

                <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                    {article.summary_ar}
                </p>

                <div className="flex items-center justify-between text-gray-500 text-xs">
                    <span>
                        <i className="far fa-clock mr-1"></i>
                        {formatDate(article.publish_date)}
                    </span>

                    <span>
                        <i className="far fa-eye mr-1"></i>
                        {article.view_count}
                    </span>
                </div>
            </div>
        </div>

        {isOpen && (
            <div
                className="video-modal"
                onClick={closePlayer}
                role="dialog"
                aria-modal="true"
            >
                <div
                    className="video-modal-content"
                    onClick={(e) => e.stopPropagation()}
                >
                    <button
                        className="video-modal-close"
                        onClick={closePlayer}
                        aria-label="Close video"
                    >
                        ×
                    </button>

                    <div className="video-player-wrapper">
                        {playerType === "youtube" && (
                            <iframe
                                title="article-player"
                                src={playerSrc}
                                frameBorder="0"
                                allow="autoplay; fullscreen"
                                allowFullScreen
                            />
                        )}

                        {playerType === "video" && (
                            <video
                                src={playerSrc}
                                controls
                                autoPlay
                                playsInline
                            />
                        )}

                        {playerType === "iframe" && (
                            <iframe
                                title="article-player"
                                src={playerSrc}
                                frameBorder="0"
                                allow="autoplay; fullscreen"
                                allowFullScreen
                            />
                        )}
                    </div>
                </div>
            </div>
        )}
    </>
);
};

export default ArticleCard;
