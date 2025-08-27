# setup-academic-theme.ps1
# Run from repo root (where .eleventy.js and src/ live):
#   powershell -ExecutionPolicy Bypass -File .\setup-academic-theme.ps1

$ErrorActionPreference = "Stop"

function Ensure-Dir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Backup($p){ if(Test-Path $p){ Copy-Item $p "$p.bak.$((Get-Date).ToString('yyyyMMdd-HHmmss'))" -Force } }
function Write-Text($p,$t){ Ensure-Dir (Split-Path $p); Set-Content -Path $p -Value $t -Encoding UTF8; Write-Host "✔ wrote $p" }
function Remove-IfExists($p){ if(Test-Path $p){ Remove-Item -Force -Recurse $p; Write-Host "✂ removed $p" } }

# Paths
$basePath  = "src/_includes/layouts/base.njk"
$homePath  = "src/index.njk"
$postsPath = "src/posts/index.njk"
$heroPath  = "src/_includes/components/hero.njk"
$cssPath   = "src/assets/css/site.css"
$debugSrc  = "src/debug.njk"

# 1) Base layout — Inter + Merriweather; Home / Posts / Toggle; no Debug
$baseNJK = @'
<!doctype html>
<html lang="en" data-theme="auto">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{% if title %}{{ title }} · {% endif %}{{ metadata.title or "Quixotic" }}</title>

  <!-- Fonts: Inter (sans) + Merriweather (serif) -->
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Merriweather:wght@400;700&display=swap" rel="stylesheet">

  <!-- Site CSS -->
  <link rel="stylesheet" href="/assets/css/site.css">
</head>
<body class="{{ bodyClass or '' }}">
  <header class="site-head">
    <a href="/" class="brand"><strong>{{ metadata.title or "Quixotic" }}</strong></a>
    <nav class="nav">
      <a href="/">Home</a>
      <a href="/posts/">Posts</a>
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
Backup $basePath
Write-Text $basePath $baseNJK

# 2) Hero partial — simple, scholarly
$heroNJK = @'
<section class="hero">
  <div class="hero__inner">
    <h1 class="hero__title">{{ metadata.title or "Quixotic" }}</h1>
    {% if metadata.description %}
      <p class="hero__tag">{{ metadata.description }}</p>
    {% else %}
      <p class="hero__tag">Research notes, analyses, and references — curated with care.</p>
    {% endif %}
  </div>
</section>
'@
Write-Text $heroPath $heroNJK

# 3) Home — parchment with translucent burgundy overlay; posts moved to /posts
$homeNJK = @'
---
layout: base.njk
title: Home
bodyClass: home-parchment
eleventyExcludeFromCollections: true
---

{% include "components/hero.njk" %}

<main class="home">
  <section class="intro">
    <p class="lead">Explore recent writing on the <a href="/posts/">Posts</a> page. Long-form, sourced, and accessible.</p>
  </section>
</main>
'@
Backup $homePath
Write-Text $homePath $homeNJK

# 4) Posts index — paginated grid (6/page)
$postsNJK = @'
---
layout: base.njk
title: Posts
pagination:
  data: collections.postsPublishedSorted
  size: 6
  alias: posts
permalink: "/posts/{% if pagination.pageNumber == 0 %}index{% else %}page/{{ pagination.pageNumber + 1 }}{% endif %}.html"
eleventyExcludeFromCollections: true
---

<main class="home">
  <h1 class="page-title">Posts</h1>
  {% if posts and posts.length %}
    <section class="post-grid">
      {% for post in posts %}
        {# rotate royal overlays by color class if provided; default burgundy #}
        <article class="card {{ post.data.color or 'burgundy' }}">
          <a href="{{ post.url }}" class="card__link" aria-label="{{ post.data.title | safe }}">
            <div class="card__media">
              {% if post.data.cover %}
                {% if img %}
                  {% img post.data.cover, post.data.coverAlt or post.data.title, [480, 720, 1024], "(min-width: 768px) 50vw, 100vw" %}
                {% else %}
                  <img src="{{ post.data.cover }}" alt="{{ post.data.coverAlt or post.data.title }}">
                {% endif %}
              {% else %}<div class="card__placeholder" aria-hidden="true">◆</div>{% endif %}
            </div>
            <div class="card__body">
              <h2 class="card__title">{{ post.data.title }}</h2>
              {% if post.data.excerpt %}<p class="card__excerpt">{{ post.data.excerpt }}</p>{% endif %}
              <p class="card__meta">
                <time datetime="{{ post.date | dateIso }}">{{ post.date | dateDisplay }}</time>
              </p>
            </div>
          </a>
        </article>
      {% endfor %}
    </section>

    {% if pagination.pages.length > 1 %}
    <nav class="pager" aria-label="Pagination">
      {% if pagination.href.previous %}<a class="pager__prev" href="{{ pagination.href.previous }}">&larr; Newer</a>{% endif %}
      <span class="pager__info">Page {{ pagination.pageNumber + 1 }} of {{ pagination.pages.length }}</span>
      {% if pagination.href.next %}<a class="pager__next" href="{{ pagination.href.next }}">Older &rarr;</a>{% endif %}
    </nav>
    {% endif %}
  {% else %}
    <p class="muted">No posts yet. Use <code>/admin</code> to publish your first one.</p>
  {% endif %}
</main>
'@
Write-Text $postsPath $postsNJK

# 5) CSS — parchment + transparent royal overlays (full, self-contained)
$css = @'
/* ===== Academic / JSTOR-ish palette =====
   Light by default; tasteful dark mode via data-theme
   No pure black: all neutrals are warm charcoals
================================================== */
:root{
  /* Parchment & neutrals */
  --bg:        #faf8f5;   /* parchment */
  --bg-soft:   #f6f1ec;   /* softer panel */
  --text:      #2c2c2c;   /* warm charcoal */
  --muted:     #6c6060;
  --hairline:  #e0d8d0;

  /* Transparent royal overlays */
  --ov-burgundy: rgba(128, 0, 32, 0.60);  /* maroon/burgundy */
  --ov-navy:     rgba(  0,33, 71, 0.40);  /* oxford blue    */
  --ov-gold:     rgba(185,151, 91, 0.40); /* muted gold     */
  --ov-forest:   rgba( 34, 78, 56, 0.38); /* forest green   */

  /* Link/brand accents */
  --brand:   #8c1f3d;     /* deep burgundy */
  --brand-ink:#4a1a26;
}

html[data-theme="dark"]{
  /* Deep parchment + soft charcoal (still no pure black) */
  --bg:       #1f1a19;
  --bg-soft:  #2a2322;
  --text:     #e9e4df;
  --muted:    #b6a8a6;
  --hairline: #3a302e;

  /* Slightly stronger overlays in dark */
  --ov-burgundy: rgba(128, 0, 32, 0.70);
  --ov-navy:     rgba(  0,33, 71, 0.55);
  --ov-gold:     rgba(185,151, 91, 0.50);
  --ov-forest:   rgba( 34, 78, 56, 0.50);

  --brand:   #d25a7b;
  --brand-ink:#e9e4df;
}

/* ===== Base type & layout */
*{box-sizing:border-box}
html,body{
  margin:0; background:var(--bg); color:var(--text);
  font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, "Helvetica Neue", Arial;
  text-rendering: optimizeLegibility;
}
h1,h2,h3{ font-family: "Merriweather", Georgia, "Times New Roman", serif; letter-spacing:.01em; }
a{ color:var(--brand); text-decoration:none }
a:hover{ text-decoration:underline; text-underline-offset:.15em }

.site-head,.site-foot{ max-width:1100px; margin:0 auto; padding:1rem;
  display:flex; align-items:center; gap:1rem }
.site-head{ justify-content:space-between; border-bottom:1px solid var(--hairline) }
.nav a{ opacity:.9; margin-right:.9rem }
.nav a:hover{ opacity:1 }
.theme-toggle{ border:1px solid var(--hairline); background:var(--bg-soft); color:inherit;
  border-radius:12px; padding:.35rem .65rem; cursor:pointer }
.brand{ font-weight:800; color:var(--brand-ink) }
.site-foot{ border-top:1px solid var(--hairline); color:var(--muted) }

.lead{ color:var(--muted); font-size:1.05rem }

/* ===== Hero — parchment + translucent burgundy wash (no opaque blocks) */
.hero{
  position:relative; overflow:clip; margin:0 0 2.25rem;
  background:
    linear-gradient(var(--ov-burgundy), rgba(128,0,32,0.0)),
    var(--bg);
  border-bottom:1px solid var(--hairline);
}
.hero__inner{ max-width:1100px; margin:0 auto; padding:3.25rem 1rem 2.25rem }
.hero__title{ font-size:clamp(2rem,4vw,3rem); font-weight:700; margin:0 0 .35rem }
.hero__tag{ margin:.2rem 0 0; color:var(--muted); max-width:70ch }

/* Optional: add a texture behind the overlay if present */
/* .hero{ background-image:
    linear-gradient(var(--ov-burgundy), rgba(128,0,32,0)),
    url('/assets/img/library-texture.jpg');
  background-size: cover; } */

/* ===== Home & posts layout */
.home{ max-width:1100px; margin:0 auto; padding:0 1rem 3rem }
.intro{ background:linear-gradient(rgba(0,0,0,0), rgba(0,0,0,0)); border:1px solid var(--hairline);
  border-radius:14px; padding:1rem; background-color:var(--bg-soft) }
.page-title{ margin:0 0 1rem }

/* ===== Post grid ===== */
.post-grid{ display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:1.15rem }
.card{
  background:var(--bg-soft); border:1px solid var(--hairline); border-radius:16px; overflow:hidden;
  transition:transform .18s ease, box-shadow .18s ease, border-color .18s;
}
.card:hover{ transform:translateY(-2px); box-shadow:0 10px 28px rgba(0,0,0,.08); border-color:transparent }
.card__link{ display:grid; grid-template-rows:150px auto; color:inherit }
.card__media{ display:grid; place-items:center; position:relative }
.card__media img{ width:100%; height:100%; object-fit:cover; display:block }
.card__placeholder{ font-size:1.6rem; opacity:.45 }
.card__body{ padding:1rem }
.card__title{ font-family:"Merriweather", Georgia, serif; font-size:1.08rem; font-weight:700; margin:0 0 .35rem }
.card__excerpt{ color:var(--muted); margin:.25rem 0 .7rem }
.card__meta{ font-size:.9rem; color:var(--muted); margin:0 }

/* Transparent royal overlays on card headers */
.card.burgundy .card__media{ background:var(--ov-burgundy) }
.card.navy    .card__media{ background:var(--ov-navy) }
.card.gold    .card__media{ background:var(--ov-gold) }
.card.forest  .card__media{ background:var(--ov-forest) }

/* Subtle diagonal grain on overlays (optional) */
.card .card__media::after{
  content:""; position:absolute; inset:0;
  background: repeating-linear-gradient(135deg, rgba(255,255,255,.06) 0 6px, rgba(255,255,255,.0) 6px 12px);
  pointer-events:none;
  mix-blend-mode:soft-light;
  opacity:.6;
}

/* Pager */
.pager{ display:flex; align-items:center; gap:.9rem; justify-content:center; margin:2rem 0; color:var(--muted) }
.pager a{ color:var(--brand) }

/* Focus ring */
:where(a,button,[tabindex]):focus-visible{ outline:2px solid #b9975b; outline-offset:2px }

/* ===== Page-specific: home parchment ===== */
.home-parchment .intro{ background-color: color-mix(in srgb, var(--bg-soft) 85%, #fff 15%) }
'@
Backup $cssPath
Write-Text $cssPath $css

# 6) Remove the old debug page if present
Remove-IfExists $debugSrc

Write-Host "`n✅ Academic theme applied."
Write-Host "• Home: parchment + translucent burgundy wash"
Write-Host "• Posts: /posts/ (paginated) with royal overlays on cards"
Write-Host "• Nav: Home / Posts / Theme toggle (no Debug)"
Write-Host "`nNow run: npx @11ty/eleventy --serve"
Write-Host "Tip: set post front matter color to one of: burgundy, navy, gold, forest"
