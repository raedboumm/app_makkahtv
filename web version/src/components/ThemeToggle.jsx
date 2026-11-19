import React from "react";

const LABEL = "الوضع الليلي";

// A sun/moon switch. `row` is the full-width version with a visible label, used
// inside the mobile menu.
const ThemeToggle = ({ isDark, onToggle, row = false }) => (
  <button
    type="button"
    role="switch"
    aria-checked={isDark}
    aria-label={LABEL}
    title={LABEL}
    className={`theme-toggle ${row ? "theme-toggle--row" : ""} ${isDark ? "is-dark" : ""}`}
    onClick={onToggle}
  >
    {row && (
      <span className="theme-toggle__label">
        <i className="fas fa-moon" aria-hidden="true"></i>
        {LABEL}
      </span>
    )}
    <span className="theme-toggle__track">
      <span className="theme-toggle__knob"></span>
      <i className="fas fa-sun" aria-hidden="true"></i>
      <i className="fas fa-moon" aria-hidden="true"></i>
    </span>
  </button>
);

export default ThemeToggle;
