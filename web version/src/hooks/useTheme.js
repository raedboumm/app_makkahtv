import { useEffect, useState } from "react";

const STORAGE_KEY = "makkah_theme";

// The saved theme is applied by the inline script in index.html before the
// first paint (so night mode never flashes white); this just reads it back.
const useTheme = () => {
  const [theme, setTheme] = useState(() =>
    document.documentElement.dataset.theme === "dark" ? "dark" : "light"
  );

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      // Storage can be blocked; the theme still applies for this visit.
    }
  }, [theme]);

  const isDark = theme === "dark";
  const toggleTheme = () => setTheme(isDark ? "light" : "dark");

  return { isDark, toggleTheme };
};

export default useTheme;
