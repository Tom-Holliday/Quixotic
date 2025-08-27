# setup-sleek.ps1
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\setup-sleek.ps1

$ErrorActionPreference = "Stop"

function Ensure-Dir($path) {
  if (!(Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}
function Write-Text($path, $text) {
  $dir = Split-Path $path
  Ensure-Dir $dir
  Set-Content -Path $path -Value $text -Encoding UTF8
  Write-Host "✔ wrote $path"
}
function Remove-IfExists($path) {
  if (Test-Path $path) { Remove-Item -Force -Recurse $path; Write-Host "✂ removed $path" }
}

# --- 0) Paths
$basePath  = "src/_includes/layouts/base.njk"
$indexPath = "src/index.njk"
$heroPath  = "src/_includes/components/hero.njk"
$cssPath   = "src/assets/css/site.css"
$debugSrc  = "src/debug.njk"

# --- 1) base.njk (sleek layout, Inter font, working toggle, NO Debug link)
$baseNJK = @'
<!doctype html>
<html lang="en" data-theme="auto">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{% if title %}{{ title }} · {% endif %}{{ metadata.title or "Quixotic" }}</title>

  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/css/site.css">
</head>
<body>
  <header class="site-head">
    <a href="/" class="brand"><strong>{{ metadata.title or "Quixotic" }}</strong></a>
    <nav class="nav">
      <a href="/">Home</a>
      <button id="theme-toggle" class="theme-toggle" aria-label="Toggle theme">🌗</button>
    </nav>
  </header>

  {{ content | safe }}

  <footer class="site-foot">
    <p>© {{ metadata.title or "Quixotic" }}</p>
  </footer>

  <script>
    (function () {
      var key = "theme";
      var html = document.documentElement;
      var btn = document.getElementById("theme-toggle");
      function apply(v){ html.setAttribute("data-theme", v); }
      var stored = null;
      try { stored = localStorage.getItem(key); } catch(e){}
      apply(stored || "auto");
      if (btn) btn.addEventListener("click", function () {
        var cur = html.getAttribute("data-theme") || "auto";
        var next = cur === "light" ? "dark" : (cur === "dark" ? "auto" : "light");
        try { localStorage.setItem(key, next); } catch(e){}
        apply(next);
      });
    })();
  </script>
</body>
</html>
'@
Write-Text $basePath $baseNJK

# --- 2) index.njk (styled post grid, no debug)
$indexNJK = @'
---
layout: base.njk
title: Home
eleventyExcludeFromCollections: true
---

{% include "components/hero.njk" ignore missing %}

<main class="home">
  {% set posts = collections.postsPublishedSorted or collections.postsSorted or collections.post %}
  {% if posts and posts.length %}
    <section class="post-grid">
      {% for post in posts | slice(0, 12) %}
        <article class="card {{ post.data.color or 'indigo' }}">
          <a href="{{ post.url }}" class="card__link" aria-label="{{ post.data.title | safe }}">
            <div class="card__media">
              {% if post.data.cover %}
                {% if img %}
                  {% img post.data.cover, post.data.coverAlt or post.data.title, [480, 720, 1024], "(min-width: 768px) 50vw, 100vw" %}
                {% else %}
                  <img src="{{ post.data.cover }}" alt="{{ post.data.coverAlt or post.data.title }}">
                {% endif %}
              {% else %}<div class="card__placeholder" aria-hidden="true">✦</div>{% endif %}
            </div>
            <div class="card__body">
              <h2 class="card__title">{{ post.data.title }}</h2>
              {% if post.data.excerpt %}<p class="card__excerpt">{{ post.data.excerpt }}</p>{% endif %}
              <p class="card__meta"><time datetime="{{ post.date | dateIso }}">{{ post.date | dateDisplay }}</time></p>
            </div>
          </a>
        </article>
      {% endfor %}
    </section>
  {% else %}
    <p style="opacity:.7">No posts yet. Use <code>/admin</code> to publish your first one.</p>
  {% endif %}
</main>
'@
Write-Text $indexPath $indexNJK

# --- 3) hero.njk (simple hero)
$heroNJK = @'
<section class="hero">
  <div class="hero__inner">
    <h1 class="hero__title">{{ metadata.title or "Quixotic" }}</h1>
    {% if metadata.description %}
      <p class="hero__tag">{{ metadata.description }}</p>
    {% else %}
      <p class="hero__tag">Notes, experiments, and the odd windmill tilt.</p>
    {% endif %}
  </div>
</section>
'@
Write-Text $heroPath $heroNJK

# --- 4) site.css (complete, with theme toggle support)
$css = @'
/* ===== Theme tokens (default dark) ===== */
:root{
  --bg:#0b0c10; --bg-soft:#12141a; --text:#f3f5f7; --muted:#b9c0ca; --hairline:#1f2430;
  --indigo:linear-gradient(135deg,#6366f1 0%, #22d3ee 100%);
  --teal:  linear-gradient(135deg,#2dd4bf 0%, #22c55e 100%);
  --rose:  linear-gradient(135deg,#fb7185 0%, #f59e0b 100%);
  --amber: linear-gradient(135deg,#f59e0b 0%, #84cc16 100%);
  --lime:  linear-gradient(135deg,#84cc16 0%, #06b6d4 100%);
}
/* System preference (auto) */
@media (prefers-color-scheme: light){
  :root{ --bg:#ffffff; --bg-soft:#f9fafb; --text:#0c1116; --muted:#445063; --hairline:#e6e6e6; }
}
/* Toggle overrides */
html[data-theme="light"]{
  --bg:#ffffff; --bg-soft:#f9fafb; --text:#0c1116; --muted:#445063; --hairline:#e6e6e6;
}
html[data-theme="dark"]{
  --bg:#0b0c10; --bg-soft:#12141a; --text:#f3f5f7; --muted:#b9c0ca; --hairline:#1f2430;
}

/* ===== Base type & header ===== */
*{box-sizing:border-box}
html,body{
  margin:0; background:var(--bg); color:var(--text);
  font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, "Helvetica Neue", Arial;
}
a{color:inherit;text-decoration:none}
a:hover{text-decoration:underline;text-underline-offset:.15em}

.site-head,.site-foot{
  max-width:1100px; margin:0 auto; padding:1rem;
  display:flex; align-items:center; gap:1rem;
}
.site-head{ justify-content:space-between; border-bottom:1px solid var(--hairline); }
.nav a{ opacity:.85; margin-right:.75rem; }
.nav a:hover{ opacity:1; }
.theme-toggle{
  border:1px solid var(--hairline); background:var(--bg-soft); color:inherit;
  border-radius:10px; padding:.35rem .6rem; cursor:pointer;
}
.brand{ font-weight:800; }

/* ===== Hero ===== */
.hero{
  position:relative; overflow:clip; margin:0 0 2.5rem;
  background:
    radial-gradient(1200px 600px at 20% -10%, rgba(99,102,241,.25), transparent 60%),
    radial-gradient(800px 400px at 80% -10%, rgba(34,211,238,.18), transparent 60%),
    var(--bg-soft);
  border-bottom:1px solid var(--hairline);
}
.hero__inner{max-width:1100px;margin:0 auto;padding:4rem 1rem 3rem;}
.hero__title{font-size:clamp(2rem,4vw,3rem);font-weight:800;letter-spacing:-.02em;margin:0;}
.hero__tag{margin:.75rem 0 0;color:var(--muted);max-width:66ch}

/* ===== Home grid ===== */
.home{max-width:1100px;margin:0 auto;padding:0 1rem 4rem;}
.post-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:1.25rem;}

.card{
  background:var(--bg-soft); border:1px solid var(--hairline); border-radius:18px; overflow:hidden;
  transition:transform .2s ease, box-shadow .2s ease, border-color .2s; will-change:transform;
}
.card:hover{ transform:translateY(-2px); box-shadow:0 10px 30px rgba(0,0,0,.18); border-color:transparent; }
.card__link{display:grid;grid-template-rows:160px auto;color:inherit}
.card__media{background:#0a0a0a;display:grid;place-items:center;position:relative}
.card__media img{width:100%;height:100%;object-fit:cover;display:block}
.card__placeholder{font-size:2rem;opacity:.35}
.card__body{padding:1rem}
.card__title{font-size:1.1rem;font-weight:700;margin:0 0 .35rem}
.card__excerpt{color:var(--muted);margin:.25rem 0 .75rem}
.card__meta{font-size:.9rem;color:var(--muted);margin:0}

/* Colored headers per-card */
.card.indigo .card__media{background-image:var(--indigo)}
.card.teal   .card__media{background-image:var(--teal)}
.card.rose   .card__media{background-image:var(--rose)}
.card.amber  .card__media{background-image:var(--amber)}
.card.lime   .card__media{background-image:var(--lime)}

/* Post splash (optional) */
.post-hero{margin:-1rem -1rem 1rem;overflow:hidden;border-bottom:1px solid var(--hairline)}
.post-hero img{width:100%;height:clamp(220px,40vh,420px);object-fit:cover;display:block}
@media (min-width:900px){ .post-hero{ border-radius:0 0 18px 18px } }

/* Focus ring */
:where(a,button,[tabindex]):focus-visible{outline:2px solid Highlight;outline-offset:2px}
'@
Write-Text $cssPath $css

# --- 5) remove debug page if present
Remove-IfExists $debugSrc

Write-Host "`nNext:"
Write-Host "  1) Run: npx @11ty/eleventy --serve"
Write-Host "  2) Open http://localhost:8080/"
Write-Host "  3) If still unstyled, open http://localhost:8080/assets/css/site.css (should show CSS text)"
