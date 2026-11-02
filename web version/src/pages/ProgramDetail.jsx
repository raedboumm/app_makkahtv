/* ==========================================================================
   🟦 PROGRAM DETAIL PAGE — Inspired by Article Detail
   Clean • Modern • Arabic RTL • Professional UI
========================================================================== */

import React, { useEffect, useRef, useState } from "react";
import { useParams, Link, useLocation } from 'react-router-dom';
import "../styles/articleDetail.css"; // Reuse article detail styles
import { Tv, SatelliteDish, User, Clock } from "lucide-react";

const ProgramDetail = () => {
    const programRef = useRef(null);
    const [progress, setProgress] = useState(0);
    const [copied, setCopied] = useState(false);
    const [fontSize] = useState(16);
    const [pageToastVisible, setPageToastVisible] = useState(false);
    const [pageToastText, setPageToastText] = useState('');
    const prevPidRef = useRef(null);
    const location = useLocation();

    const { id } = useParams();
    const pid = id ? String(id) : null;

    const currentUrl = typeof window !== 'undefined' ? window.location.href : '';

    /* -------------------------------
       ✅ Scroll Progress Bar
    --------------------------------*/
    useEffect(() => {
        const onScroll = () => {
            if (!programRef.current) return;
            const el = programRef.current;
            const total = el.scrollHeight - window.innerHeight;
            const scrolled = window.scrollY - el.offsetTop;
            const pct = Math.max(0, Math.min(1, scrolled / total)) * 100;
            setProgress(isNaN(pct) ? 0 : pct);
        };
        window.addEventListener("scroll", onScroll, { passive: true });
        onScroll();
        return () => window.removeEventListener("scroll", onScroll);
    }, []);

    /* -------------------------------
       ✅ Static Programs Data (same as Programs.jsx)
    --------------------------------*/
    const programs = [
        {
            id: 1,
            name_ar: "برنامج نور القرآن",
            description_ar: "برنامج يومي لتفسير القرآن الكريم وشرح معانيه",
            image_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGQgZShMMA8=&rs=AOn4CLDNAUH3DxjBDIGLrLMcGQVFldwDvg",
            schedule_time: "يومياً 6:00 صباحاً",
            presenter_ar: "الشيخ محمد الأحمد",
            detailed_description: "<p>يُقدم هذا البرنامج اليومي تفسيرًا شاملاً لآيات القرآن الكريم مع شرح المعاني والتفسير العلمي واللغوي. يهدف البرنامج إلى مساعدة المشاهدين على فهم القرآن الكريم بشكل أعمق وتطبيق تعاليمه في حياتهم اليومية.</p><h2>محتوى البرنامج</h2><ul><li>تفسير الآيات باللغة العربية الفصحى</li><li>شرح المعاني والمفاهيم الإسلامية</li><li>أمثلة عملية من الحياة اليومية</li><li>فتاوى وإجابات على الأسئلة</li></ul><h2>المقدم</h2><p>يقدم البرنامج الشيخ محمد الأحمد، إمام وخطيب مسجد كبير في مكة المكرمة، وهو متخصص في علوم القرآن والحديث.</p><h2>جدول البث</h2><p>يُبث البرنامج يومياً في تمام الساعة 6:00 صباحاً على قناة مكة الفضائية.</p>",
            keyFacts: [
                "برنامج يومي مخصص لتفسير القرآن",
                "يقدمه متخصصون في علوم القرآن",
                "يغطي جميع سور القرآن الكريم",
                "يجيب على أسئلة المشاهدين"
            ],
            tags: ["قرآن", "تفسير", "إسلام", "ديني"]
        },
        {
            id: 2,
            name_ar: "حديث الروح",
            description_ar: "برنامج روحاني يتناول القصص الإيمانية والعبر",
            image_url: "https://i.ytimg.com/vi/WIZ8I4pxqQA/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGUgZShlMA8=&rs=AOn4CLDQ16bdurWRL9sPfzx8jFPS9VjIgg",
            schedule_time: "الأحد 8:00 مساءً",
            presenter_ar: "د. عبدالله السعيد",
            detailed_description: "<p>برنامج \"حديث الروح\" يركز على القصص الإيمانية والعبر من حياة الصحابة والصالحين. يهدف البرنامج إلى تعزيز الإيمان وإلهام المشاهدين بالقيم الإسلامية النبيلة.</p><h2>محتوى البرنامج</h2><ul><li>قصص من حياة الصحابة والتابعين</li><li>عبر وعظات إسلامية</li><li>تحليل للأحداث التاريخية</li><li>دروس مستفادة للحياة المعاصرة</li></ul><h2>المقدم</h2><p>يقدم البرنامج الدكتور عبدالله السعيد، أستاذ الشريعة الإسلامية في جامعة أم القرى، متخصص في السيرة النبوية والتاريخ الإسلامي.</p><h2>جدول البث</h2><p>يُبث البرنامج كل يوم أحد في تمام الساعة 8:00 مساءً على قناة مكة الفضائية.</p>",
            keyFacts: [
                "برنامج أسبوعي عن القصص الإيمانية",
                "يركز على العبر والدروس المستفادة",
                "يقدمه متخصص في التاريخ الإسلامي",
                "يلهم المشاهدين بالقيم الإسلامية"
            ],
            tags: ["إيمان", "قصص", "صحابة", "عبر"]
        },
        {
            id: 3,
            name_ar: "في رحاب الحرم",
            description_ar: "جولات حصرية داخل المسجد الحرام ومعالمه",
            image_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGIgZShBMA8=&rs=AOn4CLC0Ezw_HAmkPB4O6QpRJD4t6bagZA",
            schedule_time: "الجمعة 9:00 مساءً",
            presenter_ar: "أحمد الغامدي",
            detailed_description: "<p>برنامج \"في رحاب الحرم\" يقدم جولات حصرية داخل المسجد الحرام، مستعرضاً جمال المعمار الإسلامي وتاريخ المكان المقدس. يهدف البرنامج إلى تعريف المشاهدين بمعالم المسجد الحرام وأهميته الدينية.</p><h2>محتوى البرنامج</h2><ul><li>جولات مصورة داخل المسجد الحرام</li><li>شرح تاريخي للمعالم والمباني</li><li>معلومات عن العمارة الإسلامية</li><li>قصص من تاريخ المسجد الحرام</li></ul><h2>المقدم</h2><p>يقدم البرنامج أحمد الغامدي، مرشد سياحي متخصص في المعالم الإسلامية والتاريخ الحضاري لمكة المكرمة.</p><h2>جدول البث</h2><p>يُبث البرنامج كل يوم جمعة في تمام الساعة 9:00 مساءً على قناة مكة الفضائية.</p>",
            keyFacts: [
                "جولات حصرية في المسجد الحرام",
                "يستعرض المعمار الإسلامي التاريخي",
                "يقدم معلومات عن تاريخ مكة",
                "يُبث أسبوعياً في أوقات محددة"
            ],
            tags: ["حرم", "مكة", "عمارة", "تاريخ"]
        }
    ];

    /* -------------------------------
       ✅ Load Program from Data
    --------------------------------*/
    const program = pid ? programs.find(p => String(p.id) === pid) : programs[0];

    /* -------------------------------
       ✅ Sanitize HTML (prevent XSS) — dynamic import for runtime-safe bundling
    --------------------------------*/
    // Start empty so we never inject unsanitized HTML on the first paint —
    // the body is only set after DOMPurify has cleaned it below.
    const [sanitizedBody, setSanitizedBody] = useState("");

    useEffect(() => {
        let mounted = true;
        if (typeof window === 'undefined') {
            return () => (mounted = false);
        }

        // dynamically import DOMPurify in the browser to avoid bundler/global issues
        import('dompurify')
            .then((mod) => {
                const purifier = mod && (mod.default || mod);
                const clean = purifier && purifier.sanitize ? purifier.sanitize(program?.detailed_description || "") : (program?.detailed_description || "");
                if (mounted) setSanitizedBody(clean);
            })
            .catch(() => {
                // Empty catch block
            });

        return () => (mounted = false);
    }, [program?.detailed_description]);

    /* -------------------------------
       ✅ Page Toast (Animated)
       Must stay above the early "not found" return — hooks can't be
       called conditionally.
    --------------------------------*/
    useEffect(() => {
        const newPid = pid;
        const prev = prevPidRef.current;

        if (prev === null) {
            prevPidRef.current = newPid;
            return;
        }
        if (prev === newPid) return;

        let toast = "تم الانتقال إلى برنامج جديد";

        const prevIdx = programs.findIndex((p) => String(p.id) === String(prev));
        const newIdx = programs.findIndex((p) => String(p.id) === String(newPid));

        if (prevIdx !== -1 && newIdx !== -1) {
            if (newIdx > prevIdx) toast = "برنامج لاحق →";
            else if (newIdx < prevIdx) toast = "← برنامج سابق";
        }

        setPageToastText(toast);
        setPageToastVisible(true);

        const t = setTimeout(() => setPageToastVisible(false), 1200);
        prevPidRef.current = newPid;
        return () => clearTimeout(t);
    }, [location.pathname]);

    if (!program) {
        return (
            <main className="article-detail" dir="rtl">
                <div className="container">
                    <h1>البرنامج غير موجود</h1>
                    <Link to="/programs">العودة إلى البرامج</Link>
                </div>
            </main>
        );
    }

    /* -------------------------------
       ✅ Prev / Next Computation
    --------------------------------*/
    const currentIndex = programs.findIndex(p => p.id === program.id);
    const prevProgram = currentIndex > 0 ? programs[currentIndex - 1] : null;
    const nextProgram = currentIndex < programs.length - 1 ? programs[currentIndex + 1] : null;

    /* -------------------------------
       ✅ Share Functions
    --------------------------------*/
    const shareWhatsApp = () => {
        const text = `${program.name_ar} - ${currentUrl}`;
        window.open(
            `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`,
            "_blank"
        );
    };

    const shareFacebook = () => {
        window.open(
            `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
                currentUrl
            )}`,
            "_blank"
        );
    };

    const copyLink = async () => {
        try {
            await navigator.clipboard.writeText(currentUrl);
            setCopied(true);
        } catch {
            // Empty catch block
        }
    };

    const doPrint = () => window.print();

    /* -------------------------------
       ✅ Reading Time
    --------------------------------*/
    const estimateReadingTime = (html) => {
        const text = (html || "").replace(/<[^>]*>/g, " ");
        const words = text.trim().split(/\s+/).filter(Boolean).length;
        const minutes = Math.max(1, Math.round(words / 200));
        return `${minutes} دقيقة قراءة`;
    };

    /* -------------------------------
       ✅ RENDER
    --------------------------------*/

    /* -------------------------------
       ✅ RENDER
    --------------------------------*/
    return (
        <main className="article-detail" dir="rtl">

            {/* Reading Progress */}
            <div className="reading-progress">
                <span style={{ width: `${progress}%` }} />
            </div>

            {/* Page Toast */}
            <div
                className={`page-toast ${pageToastVisible ? "show" : ""}`}
                role="status"
                aria-hidden={!pageToastVisible}
            >
                {pageToastText}
            </div>

            {/* Program Container */}
            <div className="container article-detail-inner" ref={programRef}>
                <article className="detail-card">

                    {/* SHARE BAR */}
                     

                    {/* HEADER */}
                    <header className="detail-header">
                        <span className="cat">برنامج تلفزيوني</span>
                        <h1 className="detail-title">
                            <span className="title-bar" aria-hidden="true"></span>
                            {program.name_ar}
                        </h1>

                        <div className="detail-meta">
                            <time>{program.schedule_time}</time>
                            <span className="dot">•</span>
                            <span className="views">قناة مكة</span>
                            <span className="dot hide-on-mobile">•</span>
                            <span className="hide-on-mobile">
                                {estimateReadingTime(program.detailed_description)}
                            </span>
                        </div>
                    </header>

                    {/* LEAD SECTION */}
                    <section className="lead-row">
                        <div className="lead-summary-col">
                            <p className="detail-summary">{program.description_ar}</p>

                            <div className="lead-static">
                                <p className="small"><Clock size={16} /> {program.schedule_time}</p>
                                <p className="small"><User size={16} /> {program.presenter_ar}</p>
                                <p className="small"><Tv size={16} /> قناة مكة الفضائية</p>
                                <p className="small"><SatelliteDish size={16} /> بث مباشر</p>
                            </div>
                        </div>

                        <div className="lead-extra-col">
                            {/* space for future components */}
                        </div>

                        <div className="lead-media">
                            <img src={program.image_url} loading="lazy" alt={program.name_ar} />
                        </div>
                    </section>

                    {/* BODY CONTENT */}
                    <section
                        className="detail-body"
                        style={{ fontSize: `${fontSize}px` }}
                        dangerouslySetInnerHTML={{ __html: sanitizedBody }}
                    />

                    {/* KEY FACTS */}
                    <section className="keyfacts">
                        <h3>أبرز المعلومات</h3>
                        <ul>
                            {program.keyFacts.map((k, i) => (
                                <li key={i}>{k}</li>
                            ))}
                        </ul>
                    </section>

                    {/* EXTRA DETAILS */}
                    <section className="extra-details">
                        <h3>معلومات البرنامج</h3>

                        <div className="timeline">
                            <h4>جدول البث</h4>
                            <div className="program-schedule">
                                <div className="schedule-item">
                                    <strong>الموعد:</strong> {program.schedule_time}
                                </div>
                                <div className="schedule-item">
                                    <strong>المقدم:</strong> {program.presenter_ar}
                                </div>
                                <div className="schedule-item">
                                    <strong>القناة:</strong> قناة مكة الفضائية
                                </div>
                            </div>
                        </div>
                    </section>

                    {/* TAGS */}
                    <section className="tags">
                        {program.tags.map((t, i) => (
                            <a key={i} className="tag" href="#">{t}</a>
                        ))}
                    </section>

                    {/* PRESENTER BOX */}
                    <section className="author-box">
                        <div className="presenter-avatar">
                            <User size={48} />
                        </div>
                        <div>
                            <h4>{program.presenter_ar}</h4>
                            <p className="author-role">مقدم البرنامج</p> 
                        </div>
                    </section>

                    {/* PREV / NEXT NAVIGATION */}
                    <nav className="prevnext">
                        {prevProgram ? (
                            <Link
                                to={`/programs/${prevProgram.id}`}
                                className="prev nav-link"
                            >
                                ← برنامج سابق
                            </Link>
                        ) : (
                            <button className="prev nav-disabled">← برنامج سابق</button>
                        )}

                        {nextProgram ? (
                            <Link
                                to={`/programs/${nextProgram.id}`}
                                className="next nav-link"
                            >
                                برنامج لاحق →
                            </Link>
                        ) : (
                            <button className="next nav-disabled">برنامج لاحق →</button>
                        )}
                    </nav>

                    {/* SUGGESTIONS */}
                    <footer className="detail-footer">
                        <h3>برامج أخرى</h3>

                        <div className="suggestions-grid">
                            {programs.filter(p => p.id !== program.id).map((p, i) => (
                                <div key={i} className="suggestion-item">
                                    <div className="program-card">
                                        <img
                                            src={p.image_url}
                                            alt={p.name_ar}
                                            className="program-image"
                                        />
                                        <div className="program-content">
                                            <h3 className="program-name">{p.name_ar}</h3>
                                            <p className="program-description">{p.description_ar}</p>
                                            <div className="program-meta">
                                                <div className="meta-item">
                                                    <i className="fas fa-clock"></i>
                                                    <span>{p.schedule_time}</span>
                                                </div>
                                                {p.presenter_ar && (
                                                    <div className="meta-item">
                                                        <i className="fas fa-user"></i>
                                                        <span>{p.presenter_ar}</span>
                                                    </div>
                                                )}
                                            </div>
                                            <Link to={`/programs/${p.id}`} className="program-link">
                                                عرض التفاصيل
                                            </Link>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </footer>

                </article>
            </div>
        </main>
    );
};
 
export default ProgramDetail;