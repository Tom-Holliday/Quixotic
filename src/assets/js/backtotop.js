(function(){
  const btn = document.getElementById("backToTop");
  if(!btn) return;
  const onScroll = () => {
    window.scrollY > 600 ? btn.classList.add("show") : btn.classList.remove("show");
  };
  btn.addEventListener("click", () => window.scrollTo({ top: 0, behavior: "smooth" }));
  document.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
})();
