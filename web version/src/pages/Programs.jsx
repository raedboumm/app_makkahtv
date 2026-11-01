// ✅ src/pages/ProgramsPage.jsx
import React from "react";
import { Link } from "react-router-dom";
import "../styles/programs.css"; // <-- مهم جداً
import { Tv, Clapperboard, CalendarClock, SatelliteDish } from "lucide-react";


const ProgramsPage = () => {
  // Static programs data
  const programs = [
    {
      id: 1,
      name_ar: "برنامج نور القرآن",
      description_ar: "برنامج يومي لتفسير القرآن الكريم وشرح معانيه",
      image_url: "https://i.ytimg.com/vi/QlasJcax37k/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGQgZShMMA8=&rs=AOn4CLDNAUH3DxjBDIGLrLMcGQVFldwDvg",
      schedule_time: "يومياً 6:00 صباحاً",
      presenter_ar: "الشيخ محمد الأحمد"
    },
    {
      id: 2,
      name_ar: "حديث الروح",
      description_ar: "برنامج روحاني يتناول القصص الإيمانية والعبر",
      image_url: "https://i.ytimg.com/vi/WIZ8I4pxqQA/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGUgZShlMA8=&rs=AOn4CLDQ16bdurWRL9sPfzx8jFPS9VjIgg",
      schedule_time: "الأحد 8:00 مساءً",
      presenter_ar: "د. عبدالله السعيد"
    },
    {
      id: 3,
      name_ar: "في رحاب الحرم",
      description_ar: "جولات حصرية داخل المسجد الحرام ومعالمه",
      image_url: "https://i.ytimg.com/vi/hE9VDhUDT-4/hqdefault.jpg?sqp=-oaymwFBCNACELwBSFryq4qpAzMIARUAAIhCGAHYAQHiAQoIGBACGAY4AUAB8AEB-AH-CYAC0AWKAgwIABABGGIgZShBMA8=&rs=AOn4CLC0Ezw_HAmkPB4O6QpRJD4t6bagZA",
      schedule_time: "الجمعة 9:00 مساءً",
      presenter_ar: "أحمد الغامدي"
    }
  ];

  // Static live interviews data
  const liveInterviews = [
    {
      id: 1,
      name_ar: "لقاء مع علماء الأمة",
      description_ar: "حوارات مباشرة مع كبار العلماء والمفكرين",
      image_url: "https://i.ytimg.com/vi/dGY1RVobDPU/hqdefault.jpg?sqp=-oaymwEXCOADEI4CSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA30tjcF-4DqZjWp5KYMegFpWPfXw",
      schedule_time: "الثلاثاء 10:00 مساءً",
      presenter_ar: "خالد المالكي"
    },
    {
      id: 2,
      name_ar: "ضيف المساء",
      description_ar: "لقاءات حصرية مع شخصيات مؤثرة في العالم الإسلامي",
      image_url: "https://i.ytimg.com/vi/qKS9sC3nl_c/hqdefault.jpg?sqp=-oaymwEXCOADEI4CSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLBFO9qOT6kiybTVT1xPL_LH2S1yCg",
      schedule_time: "الأربعاء 11:00 مساءً",
      presenter_ar: "فهد الشمري"
    },
    {
      id: 3,
      name_ar: "حوار مفتوح",
      description_ar: "نقاشات مباشرة حول قضايا الساعة الدينية والاجتماعية",
      image_url: "https://i.ytimg.com/vi/BOk9o1GpTUo/hqdefault.jpg?sqp=-oaymwEXCOADEI4CSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLA5PunT7dr97u-E2qkIvoY6VZVVYw",
      schedule_time: "السبت 9:30 مساءً",
      presenter_ar: "سعد القحطاني"
    }
  ];

  return (
    <div className="programs-wrapper">
      <div className="container">
        {/* العنوان الرئيسي - برامج قناة مكة */}
        
 <div className="schedule-header">
                        <h2 className="programs-title"><i><CalendarClock className="w-6 h-6" size={40} />  </i> 
          برامج قناة مكة</h2>
                         <p>
                          
                         </p>
                    </div>
        {/* شبكة البطاقات - البرامج */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {programs.map((program) => (
            /* <Link key={program.id} to={`/programs/${program.id}`} className="program-card-link"> */
              <div className="program-card">
                <img
                  src={program.image_url}
                  alt={program.name_ar}
                  className="program-image"
                />

                <div className="program-content">
                  <h3 className="program-name">{program.name_ar}</h3>
                  <p className="program-description">{program.description_ar}  </p>

                  <div className="program-meta">
                    <div className="meta-item">
                      <i className="fas fa-clock"></i>
                      <span>{program.schedule_time}</span>
                    </div>

                    {program.presenter_ar && (
                      <div className="meta-item">
                        <i className="fas fa-user"></i>
                        <span>{program.presenter_ar}</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
          /*   </Link> */
          ))}
        </div>

        {/* العنوان الرئيسي - اللقاءات المباشرة */}
        <h1 className="programs-title flex items-center gap-3" style={{ marginTop: '4rem' }}>
          <i className="fas fa-microphone"></i>
          اللقاءات المباشرة
        </h1>

        {/* شبكة البطاقات - اللقاءات المباشرة */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {liveInterviews.map((interview) => (
            <div key={interview.id} className="program-card">
              <img
                src={interview.image_url}
                alt={interview.name_ar}
                className="program-image"
              />

              <div className="program-content">
                <h3 className="program-name">{interview.name_ar}</h3>
                <p className="program-description">{interview.description_ar}</p>

                <div className="program-meta">
                  <div className="meta-item">
                    <i className="fas fa-clock"></i>
                    <span>{interview.schedule_time}</span>
                  </div>

                  {interview.presenter_ar && (
                    <div className="meta-item">
                      <i className="fas fa-user"></i>
                      <span>{interview.presenter_ar}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ProgramsPage;
