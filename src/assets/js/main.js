(function () {
  /* =========================
     Status band clock
     ========================= */

  function startStatusBandClock() {
    const dateEl = document.getElementById("statusband-date");
    const timeEl = document.getElementById("statusband-time");
    if (!dateEl || !timeEl) return;

    function tick() {
      const now = new Date();

      dateEl.textContent = now.toLocaleDateString(undefined, {
        year: "numeric",
        month: "long",
        day: "2-digit",
      });

      timeEl.textContent = now.toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      });
    }

    tick();
    setInterval(tick, 1000);
  }

  /* =========================
     About section bounce
     ========================= */

  function initAboutBounce() {
    const grid = document.querySelector("#about.about--bounce .about__grid");
    if (!grid) return;

    const bounce = () => {
      grid.classList.remove("is-bouncing");
      void grid.offsetWidth; // force reflow
      grid.classList.add("is-bouncing");
    };

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) bounce();
        });
      },
      { threshold: 0.3 }
    );

    observer.observe(grid);
  }

  /* =========================
     DOM ready
     ========================= */

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      startStatusBandClock();
      initAboutBounce();
    });
  } else {
    startStatusBandClock();
    initAboutBounce();
  }
})();
