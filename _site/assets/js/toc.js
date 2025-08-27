/* toc.js — builds a sticky Table of Contents with scroll-spy.
   Looks for:
     - TOC container:  #js-toc  (inside your sidebar)
     - Article root:   .post-main (falls back to <article>)
   Heads up:
     - Uses only vanilla JS. No dependencies.
     - Works with or without markdown-it-anchor; will add IDs if missing.
*/

(function () {
  const tocContainer = document.getElementById("js-toc");
  if (!tocContainer) return;

  // Find the article content area
  const article =
    document.querySelector(".post-main") ||
    document.querySelector("article");
  if (!article) return;

  // Collect headings (h2/h3) in reading order
  const headings = Array.from(article.querySelectorAll("h2, h3")).filter(h => h.textContent.trim().length);
  if (!headings.length) {
    // Hide the entire TOC block if no headings
    const aside = tocContainer.closest(".toc, aside") || tocContainer.parentElement;
    if (aside) aside.style.display = "none";
    return;
  }

  // Ensure each heading has a stable, unique ID
  const used = new Set();
  function slugify(str) {
    return str.trim().toLowerCase()
      .replace(/[^\w\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  }
  function uniqueId(base) {
    let id = base || "section";
    let n = 2;
    while (used.has(id) || document.getElementById(id)) {
      id = `${base}-${n++}`;
    }
    used.add(id);
    return id;
  }
  headings.forEach(h => {
    if (h.id) { used.add(h.id); return; }
    const base = slugify(h.textContent) || "section";
    h.id = uniqueId(base);
  });

  // Build a flat UL with nested class hooks for styling
  const ul = document.createElement("ul");
  ul.className = "toc-items";
  const links = [];

  headings.forEach(h => {
    const li = document.createElement("li");
    li.className = `toc-item toc-${h.tagName.toLowerCase()}`;
    const a = document.createElement("a");
    a.href = `#${h.id}`;
    a.textContent = h.textContent;
    a.setAttribute("data-toc-target", h.id);
    a.setAttribute("role", "link");
    li.appendChild(a);
    ul.appendChild(li);
    links.push(a);
  });

  // Render into container (clear first in case of HMR)
  tocContainer.innerHTML = "";
  tocContainer.appendChild(ul);

  // Smooth scroll (respect reduced motion)
  const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  function scrollToHeading(id) {
    const el = document.getElementById(id);
    if (!el) return;
    // If you have a fixed header, give headings CSS: scroll-margin-top
    el.scrollIntoView({ behavior: prefersReduced ? "auto" : "smooth", block: "start" });
    // Move focus for accessibility when user clicks in TOC
    el.setAttribute("tabindex", "-1");
    el.focus({ preventScroll: true });
    // Clean up tabindex later
    setTimeout(() => el.removeAttribute("tabindex"), 1000);
  }

  // Click handlers
  ul.addEventListener("click", (e) => {
    const a = e.target.closest("a[data-toc-target]");
    if (!a) return;
    const id = a.getAttribute("data-toc-target");
    // Let normal hash update happen but do custom scroll
    e.preventDefault();
    history.pushState(null, "", `#${id}`);
    scrollToHeading(id);
  });

  // Scroll-spy: highlight active section
  // Uses an IntersectionObserver with a rootMargin to trigger a bit before the heading hits the top.
  const activeClass = "is-active";
  const byId = Object.fromEntries(links.map(a => [a.getAttribute("data-toc-target"), a]));

  // Clear all active states
  function clearActive() { links.forEach(a => a.classList.remove(activeClass)); }
  function setActive(id) {
    if (!id) return;
    clearActive();
    const a = byId[id];
    if (a) a.classList.add(activeClass);
  }

  // If the page loaded with a hash, mark it active
  if (location.hash && byId[location.hash.slice(1)]) {
    setActive(location.hash.slice(1));
  }

  // Observe headings
  const observer = new IntersectionObserver((entries) => {
    // Sort entries by viewport proximity (highest intersectionRatio first)
    entries.sort((a, b) => b.intersectionRatio - a.intersectionRatio);
    for (const entry of entries) {
      if (entry.isIntersecting) {
        setActive(entry.target.id);
        return;
      }
    }
    // Fallback: if nothing intersecting (e.g., scrolled to very top), highlight the first
    const first = headings[0];
    if (first && window.scrollY < first.getBoundingClientRect().top + window.scrollY) {
      setActive(first.id);
    }
  }, {
    // Trigger when the heading crosses 20% from top of viewport
    root: null,
    rootMargin: "-20% 0px -70% 0px",
    threshold: [0, 0.25, 0.5, 1]
  });

  headings.forEach(h => observer.observe(h));

  // Accessibility: keyboard support for TOC list (arrow up/down to move focus)
  ul.addEventListener("keydown", (e) => {
    const current = document.activeElement;
    if (!ul.contains(current)) return;
    const idx = links.indexOf(current);
    if (e.key === "ArrowDown") {
      e.preventDefault();
      const next = links[Math.min(idx + 1, links.length - 1)];
      next && next.focus();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      const prev = links[Math.max(idx - 1, 0)];
      prev && prev.focus();
    }
  });

  // Optional: collapse TOC on very small screens (CSS usually hides it; this is a safety)
  function responsiveHide() {
    const aside = tocContainer.closest(".toc, aside") || tocContainer.parentElement;
    if (!aside) return;
    if (window.matchMedia("(max-width: 1024px)").matches) {
      aside.hidden = true;
    } else {
      aside.hidden = false;
    }
  }
  responsiveHide();
  window.addEventListener("resize", responsiveHide);
})();

