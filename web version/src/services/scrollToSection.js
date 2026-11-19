// Scrolls a homepage section (e.g. the live player, #live-hero) into view
// right under the sticky header.
//
// The header sits in the normal page flow (position: sticky) and changes
// height: the mobile menu opens inside it, and the date bar + brown border
// collapse once the page is scrolled. Measuring the target once, up front,
// therefore lands in the wrong place on phones (the open menu's height gets
// added, so the player is scrolled past). Instead we wait for the layout to
// settle, scroll, then re-measure and correct once the header has finished
// shrinking.
const HEADER_TRANSITION_MS = 400;

const targetTop = (el) => {
  const header = document.querySelector(".header");
  const headerHeight = header ? header.getBoundingClientRect().height : 0;
  const top = el.getBoundingClientRect().top + window.pageYOffset - headerHeight;
  return Math.max(0, Math.round(top));
};

export const scrollToSection = (id) => {
  // Two frames: let React close the mobile menu / swap the hero video first.
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      const el = document.getElementById(id);
      if (!el) return;

      window.scrollTo({ top: targetTop(el), behavior: "smooth" });

      // Re-align after the smooth scroll and the header's shrink transition.
      let done = false;
      const realign = () => {
        if (done) return;
        done = true;
        window.removeEventListener("scrollend", onScrollEnd);
        setTimeout(() => {
          const fixed = targetTop(el);
          if (Math.abs(window.pageYOffset - fixed) > 4) {
            window.scrollTo({ top: fixed, behavior: "smooth" });
          }
        }, HEADER_TRANSITION_MS);
      };
      const onScrollEnd = () => realign();
      window.addEventListener("scrollend", onScrollEnd);
      // Fallback for browsers without `scrollend` (older Safari).
      setTimeout(realign, 900);
    })
  );
};

export default scrollToSection;
