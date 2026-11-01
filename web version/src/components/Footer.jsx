import React from "react";
import "../styles/footer.css";
import logo from "../assets/smallIcon.png"; // keep this path as you have it


const Footer = () => {
   const currentYear = new Date().getFullYear();
     const menuItems = [
    { name: "الرئيسية", page: "/", icon: "fa-home" },
    { name: "البث المباشر", page: "/live", icon: "fa-broadcast-tower" },
    { name: "برامجنا", page: "/programs", icon: "fa-tv" },
    { name: "البث اليومي", page: "/daily", icon: "fa-video" },
    { name: "تواصل معنا", page: "/contact", icon: "fa-envelope" },
  ];
  return (
    <footer className="footer">
      <div className="container footer__wrap">
        <div className="footer__grid">
          {/* About */}
          <div className="footer__col">
            <h3 style={{marginTop:"-15px" ,marginRight:"-1px"}} className="footer__title">
              <span className="footer__logoWrap">
                <img className="footer__logo" src={logo} alt="makkah logo" />
              </span>
              قناة مكة
            </h3>

            <p className="footer__text">
نعمل لإيصال الهدى للعالمين وتقديم البناء العبادي والمجتمعي وفق مراد الله عز وجل ما أمكن، بتفعيل ثلاثية الهدى:القرآن،الرسول ﷺ،البيت الحرام
            </p>
          </div>

          {/* Quick Links */}
          <div className="footer__col">
            <h3 className="footer__title">روابط سريعة</h3>
            <ul className="footer__links">
              <li>
                <a href="/privacy" className="footer__link">
                  <i className="fa-solid fa-chevron-left footer__chev"></i>
                  سياسة الخصوصية
                </a>
              </li>
              <li>
                <a href="/contact" className="footer__link">
                  <i className="fa-solid fa-chevron-left footer__chev"></i>
                  تواصل معنا
                </a>
              </li>
            </ul>
          </div>

          {/* Sections */}
          <div className="footer__col">
            <h3 className="footer__title">الأقسام</h3>
            <ul className="footer__links">
              <li>
                <a href="/" className="footer__link">
                  <i className="fa-solid fa-chevron-left footer__chev"></i>
                 الرئيسية
                </a>
              </li>
              <li>
                <a href="/programs" className="footer__link">
                  <i className="fa-solid fa-chevron-left footer__chev"></i>
                  برامجنا
                </a>
              </li>
              <li>
                <a href="/daily" className="footer__link">
                  <i className="fa-solid fa-chevron-left footer__chev"></i>
                
البث اليومي
                </a>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div className="footer__col">
            <a href="/contact" className="footer__title footer__title--link">تواصل معنا</a>
            <div className="footer__contact">
              <p className="footer__text">
                <i className="fa-solid fa-envelope footer__goldIcon"></i>
                info@makkahtv.tv
              </p>

              <div className="footer__social">
                <a href="https://www.facebook.com/MakkahTV" className="socialBtn" target="_blank" rel="noopener noreferrer" aria-label="Facebook">
                  <i className="fa-brands fa-facebook-f"></i>
                </a>
                <a href="https://x.com/MakkahTV" className="socialBtn" target="_blank" rel="noopener noreferrer" aria-label="Twitter / X">
                  <i className="fa-brands fa-x"></i>
                </a>
                <a href="https://www.youtube.com/MakkahTV" className="socialBtn" target="_blank" rel="noopener noreferrer" aria-label="YouTube">
                  <i className="fa-brands fa-youtube"></i>
                </a>
                <a href="https://www.instagram.com/makkahtv/" className="socialBtn" target="_blank" rel="noopener noreferrer" aria-label="Instagram">
                  <i className="fa-brands fa-instagram"></i>
                </a>
                <a href="https://www.tiktok.com/@makkahtv.tv" className="socialBtn" target="_blank" rel="noopener noreferrer" aria-label="tiktok">
                  <i className="fa-brands fa-tiktok"></i>
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom line */}
 
        <div className="footer__bottom">
          <p>© {currentYear} قناة مكة الفضائية. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
