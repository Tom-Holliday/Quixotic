(function () {
  document.addEventListener('DOMContentLoaded', () => {
    if (!window.VanillaTilt) {
      console.error('❌ VanillaTilt not loaded');
      return;
    }
    const els = document.querySelectorAll('.about-tilt');
    console.log('✅ Tilt targets found:', els.length);
    if (!els.length) return;

    VanillaTilt.init(els, {
      max: 15,
      speed: 400,
      glare: true,
      "max-glare": 0.3,
      perspective: 800,
      scale: 1.05
    });
  });
})();
