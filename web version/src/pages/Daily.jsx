import React from "react";
import { Link } from "react-router-dom";
import "../styles/daily.css";
import { dailySchedule } from "../data/dailySchedule";
import programMakhtv from "../assets/program_makhtv.jpg";
import icon from "../assets/icon.png";

const Daily = () => {
    const scheduleData = dailySchedule;

    return (
        <div className="daily-wrapper">
            {/* Hero Section */}
       

            {/* Schedule Grid */}
            <section className="daily-schedule">
                <div className="container">
                    <div className="schedule-header">
                        <h2>البث اليومي</h2>
                        <p>احرص على عدم تفويت أي برنامج من برامجنا الخاصة</p>
                    </div>

                      
                    <div className="highlights-grid">
                        
                        <div className="highlight-card">
                            <img src="https://tse3.mm.bing.net/th/id/OIP.sY-EBs0KfTJsBgviGEjJ9QHaEo?rs=1&pid=ImgDetMain&o=7&rm=3" alt="مبرور" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>مبرور</h3>
                            <p>برنامج توعوي يستهدف الحاج والمعتمر والزائر للمشاعر المقدسة</p>
                            <span className="time-badge">03:00 صباحا</span>
                        </div>
                        <div className="highlight-card featured">
                            <img src="https://th.bing.com/th/id/OIP.sXHhlD67I7ASj8gktNLwTQHaEK?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3" alt="قيم الزحام" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>قيم الزحام</h3>
                            <p>برنامج صباحي يحمل روح الروحانية منذ الفجر</p>
                            <span className="time-badge">03:30 صباحا</span>
                        </div>


                        <div className="highlight-card">
                            <img src="https://tse2.mm.bing.net/th/id/OIP.hd3s6LoBEA09xi4AbTuw4wHaEJ?rs=1&pid=ImgDetMain&o=7&rm=3" alt="دروس الحرم" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>استكشاف حدود الحرم</h3>
                            <p>برنامج  تعريفي بمعالم والأنصاب التي تحدد الحرم المكي</p>
                            <span className="time-badge">08:15 صباحا</span>
                        </div>

                        <div className="highlight-card">
                            <img src="https://tse4.mm.bing.net/th/id/OIP.exvEBk30EIcc2X94UdWk5QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3" alt="أرث الخليلين" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>أرث الخليلين</h3>
                            <p>برنامج  توعوي يتم تقديمه خلال موسم الحج</p>
                            <span className="time-badge">08:30 صباحا</span>
                        </div>

                        <div className="highlight-card">
                            <img src={programMakhtv} alt="آيات الحج" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>آيات الحج</h3>
                            <p>تأملات دينية حول مناسك الحج والعمرة</p>
                            <span className="time-badge">09:15 صباحا</span>
                        </div>

                        <div className="highlight-card">
                            <img src="https://tse4.mm.bing.net/th/id/OIP.BtWWY5gn2oQlyf8lRBnCswHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3" alt="دروس الحرم" className="highlight-image" />
                            <div className="highlight-icon">
                                <img src={icon} alt="icon" />
                            </div>
                            <h3>دروس الحرم</h3>
                            <p>دروس تعليمية مباشرة من المسجد الحرام</p>
                            <span className="time-badge">10:00 صباحا</span>
                        </div>

                    </div>
                 
                </div>
            </section>

            {/* Highlights Section */}
    
            {/* CTA Section */}
            <section className="daily-cta">
                <div className="container">
                    <div className="cta-content">
                        <h2>لا تفوّت أي برنامج</h2>
                        <p>اشترك في إشعاراتنا لتصلك تنبيهات البرامج الجديدة</p>
                        <Link to="/contact" className="cta-button">
                            <i className="fas fa-envelope"></i>
                            تواصل معنا
                        </Link>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default Daily;
