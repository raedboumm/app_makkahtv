import { useMemo, useRef } from "react";

// Fisher-Yates, on a copy.
const shuffle = (items) => {
  const list = [...items];
  for (let i = list.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
};

// Returns `items` (each with an `id`) in a random order that is new on every
// visit, since the order lives only as long as the component stays mounted.
// While mounted it stays put: items that arrive later (the catalog loads page
// by page) are shuffled and added at the end, so visible cards never jump.
const useRandomOrder = (items) => {
  const orderRef = useRef([]);

  return useMemo(() => {
    if (!items) return [];
    const known = new Set(orderRef.current.map((item) => item.id));
    const fresh = items.filter((item) => !known.has(item.id));
    if (fresh.length > 0) orderRef.current = [...orderRef.current, ...shuffle(fresh)];
    return orderRef.current;
  }, [items]);
};

export default useRandomOrder;
