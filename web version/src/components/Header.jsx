import React, { useState, useEffect } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import "../styles/header.css";
import logo from "../assets/logos.png"; // keep this path as you have it

const Header = () => {
  const [searchOpen, setSearchOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  // Scroll-anchor nav items (live section, episodes, ...) only exist on the
  // homepage. From any other page, navigate home first and let Home.jsx pick
  // up the pending target once its sections actually exist in the DOM.
  const goToSection = (id, live) => {
    if (location.pathname === "/") {
      if (live) window.dispatchEvent(new Event("makkah:go-live"));
      const el = document.getElementById(id);
      if (el) {
        const offset = 100;
        const elementPosition = el.getBoundingClientRect().top + window.pageYOffset;
        window.scrollTo({ top: elementPosition - offset, behavior: "smooth" });
      }
      return;
    }

    sessionStorage.setItem("makkah_pending_scroll", JSON.stringify({ id, live: !!live }));
    navigate("/");
  };

  // Clicking a link to the page you're already on doesn't trigger a route
  // change (so ScrollToTop never fires) — scroll to top manually instead.
  const handleSamePageClick = (targetPath) => {
    if (location.pathname === targetPath) {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };

  const [isSticky, setIsSticky] = useState(false);

  const menuItems = [
       { name: "الرئيسية", page: "/", icon: "fa-home" },
   { name: "البث المباشر", page: "live-hero", live: true },
{ name: "مكتبة البرامج", page: "/library", icon: "fa-film" },
  /*  { name: "البث المباشر", page: "/live", icon: "fa-broadcast-tower" },*/
 /*   { name: "برامجنا", page: "/programs", icon: "fa-tv" },*/
 /*   { name: "البث اليومي", page: "/daily", icon: "fa-video" },*/
  ];

  // 📅 dynamic date — Hijri only
  const today = new Date();
  const hijriDateStr = new Intl.DateTimeFormat("ar-SA-u-ca-islamic-umalqura", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(today);

  // Hides the top date/social bar on scroll and grows the main nav a bit to
  // fill the space, reverting back once you're near the top again. (The
  // earlier "bounce/glitch" was actually a leftover placeholder .header
  // rule in index.css fighting this one over position/z-index/background —
  // that's been removed, so this scroll effect is safe now.)
  useEffect(() => {
    let ticking = false;
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      window.requestAnimationFrame(() => {
        setIsSticky((prev) => (prev ? window.scrollY > 40 : window.scrollY > 90));
        ticking = false;
      });
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <>
      <header className={`header ${isSticky ? "header--scrolled" : ""}`}>
        {/* ✅ Top Bar */}
        <div className="header-top">
          <div className="container header-top-content">
            <span className="header-date">
              <i className="fa-regular fa-calendar"></i> {hijriDateStr}
            </span>
            <div className="header-social">
              <a href="https://www.facebook.com/MakkahTV" target="_blank" rel="noopener noreferrer" ><i className="fab fa-facebook"></i></a>
              <a href="https://x.com/MakkahTV" target="_blank" rel="noopener noreferrer" ><i className="fab fa-x"></i></a>
              <a href="https://www.youtube.com/MakkahTV" target="_blank" rel="noopener noreferrer" ><i className="fab fa-youtube"></i></a>
              <a href="https://www.instagram.com/makkahtv/" target="_blank" rel="noopener noreferrer" ><i className="fab fa-instagram"></i></a>
              <a href="https://www.tiktok.com/@makkahtv.tv" target="_blank" rel="noopener noreferrer" ><i className="fab fa-tiktok"></i></a>
            </div>
          </div>
        </div>

        {/* ✅ Main Header */}
        <div className="container header-main">
          {/* Logo */}

          <div className="logo-box">
            <Link to="/" onClick={() => handleSamePageClick("/")}>
              <img
                src={logo}
                alt="Makkah TV logo"
              />
            </Link>
          </div>


          {/* ✅ Desktop Navbar */}
<nav className="nav-desktop">
  {menuItems.map((item, i) => (
    item.page.startsWith("/") ? (
      <Link
        key={i}
        to={item.page}
        className={`nav-link ${location.pathname === item.page ? "active-link" : ""}`}
        onClick={() => handleSamePageClick(item.page)}
      >
        <i className={`fas ${item.icon}`}></i>
        <span>{item.name}</span>
        {item.live && <span className="live-nav-dot"></span>}
      </Link>
    ) : (
      <button
          key={i}
          className="nav-link"
          onClick={() => goToSection(item.page, item.live)}
        >
        <i className={`fas ${item.icon}`}></i>
        <span>{item.name}</span>
        {item.live && <span className="live-nav-dot"></span>}
      </button>
    )
  ))}
</nav>

          {/* Search & Mobile Icons */}
          <div className="header-actions">
            <button onClick={() => setMobileMenuOpen(!mobileMenuOpen)} className="menu-btn">
              <i className="fas fa-bars"></i>
            </button>
          </div>
        </div>

        {/* ✅ Search Bar */}
        {searchOpen && (
          <div className="search-box container">
            <input type="text" placeholder="ابحث عن الأخبار والفيديوهات..." />
          </div>
        )}

        {/* ✅ Mobile Menu */}
        {/* ✅ Mobile Menu */}
{mobileMenuOpen && (
  <div className="mobile-menu">
    {menuItems.map((item, i) =>
      item.page.startsWith("/") ? (
        <Link
          key={i}
          to={item.page}
          className={location.pathname === item.page ? "active-link" : ""}
          onClick={() => {
            handleSamePageClick(item.page);
            setMobileMenuOpen(false);
          }}
        >
          <i className={`fas ${item.icon}`}></i>
          {item.name}
          {item.live && <span className="live-nav-dot"></span>}
        </Link>
      ) : (
          <button
              key={i}
              className="mobile-link"
              onClick={() => {
                goToSection(item.page, item.live);
                setMobileMenuOpen(false);
              }}
            >
          <i className={`fas ${item.icon}`}></i>
          {item.name}
          {item.live && <span className="live-nav-dot"></span>}
        </button>
      )
    )}
  </div>
)}
      </header>
    </>
  );
};

export default Header;
