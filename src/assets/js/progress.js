(function () {
  const bar = document.createElement("div");
  bar.setAttribute("id", "reading-progress");
  Object.assign(bar.style, {
    position: "fixed",
    top: "0", left: "0", height: "3px", width: "0%",
    background: "linear-gradient(90deg, var(--accent), var(--accent-strong))",
    zIndex: "9999", transition: "width .1s linear"
  });
  document.body.appendChild(bar);

  const el = document.querySelector("main") || document.body;
  const update = () => {
    const max = (el.scrollHeight - window.innerHeight);
    const pct = max > 0 ? (window.scrollY / max) * 100 : 0;
    bar.style.width = Math.min(100, Math.max(0, pct)) + "%";
  };
  document.addEventListener("scroll", update, { passive: true });
  window.addEventListener("resize", update);
  update();
})();
