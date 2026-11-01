import { useEffect, useState } from "react";

const BackToTop = () => {
  const [visible, setVisible] = useState(false);
  const [hover, setHover] = useState(false);

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 300);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const baseStyle = {
    position: "fixed",
    bottom: "24px",
    left: "24px",
    width: "45px",
    height: "45px",
    borderRadius: "5px",
    background: "#d7ac5b",                 // accent
    border: "1px solid #353333",         // gray stroke
    color: "#1a1a1a",                    // black icon (if text)
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    cursor: "pointer",
    boxShadow: "0 8px 22px rgba(0,0,0,0.25)",
    zIndex: 9999,
    transition: "transform .2s ease, box-shadow .2s ease, filter .2s ease",
    // optional subtle blur sheen
    backdropFilter: "saturate(120%)",
  };

  const hoverStyle = hover
    ? {
        transform: "translateY(-2px) scale(1.06)",
        boxShadow:
          "0 10px 28px rgba(0,0,0,0.28), 0 0 0 3px rgba(255, 222, 173, 0.45)", // wheat glow
        filter: "brightness(1.03)",
      }
    : {};

  const iconStyle = {
    width: 20,
    height: 20,
    fill: "#1a1a1a", // black icon on wheat
    transition: "transform .2s ease",
    transform: hover ? "rotate(-15deg)" : "none",
  };

  if (!visible) return null;

  return (
    <button
      aria-label="العودة إلى الأعلى"
      onClick={scrollToTop}
      style={{ ...baseStyle, ...hoverStyle }}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
    >
      {/* SVG Arrow (consistent across browsers) */}
      <svg viewBox="0 0 24 24" style={iconStyle} xmlns="http://www.w3.org/2000/svg">
        <path d="M12 5.5c.3 0 .6.12.82.34l6.34 6.34a1.16 1.16 0 1 1-1.64 1.64L13.16 9.78V18a1.16 1.16 0 1 1-2.32 0V9.78l-4.36 4.34a1.16 1.16 0 1 1-1.64-1.64l6.34-6.34c.22-.22.52-.34.82-.34Z"/>
      </svg>
    </button>
  );
};

export default BackToTop;
