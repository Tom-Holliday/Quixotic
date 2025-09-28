// src/assets/js/theme.js
(function () {
  const html = document.documentElement;

  function applySavedTheme() {
    try {
      const saved = localStorage.getItem("theme");
      if (saved === "light" || saved === "dark") {
        html.setAttribute("data-theme", saved);
      }
    } catch (_) {}
  }

  function toggleTheme() {
    const current = html.getAttribute("data-theme") || "dark";
    const next = current === "light" ? "dark" : "light";
    html.setAttribute("data-theme", next);
    try { localStorage.setItem("theme", next); } catch (_) {}
  }

  // Apply any saved theme ASAP
  applySavedTheme();

  // Hook up the button
  document.addEventListener("DOMContentLoaded", () => {
    const btn = document.getElementById("theme-toggle");
    if (btn) btn.addEventListener("click", toggleTheme, { passive: true });
  });
})();
