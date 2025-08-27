# setup-hero-quixote.ps1
# Run:
#   powershell -ExecutionPolicy Bypass -File .\setup-hero-quixote.ps1

$ErrorActionPreference = "Stop"

function Ensure-Dir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Backup($p){ if(Test-Path $p){ Copy-Item $p "$p.bak.$((Get-Date).ToString('yyyyMMdd-HHmmss'))" -Force } }
function Write-Text($p,$t){ Ensure-Dir (Split-Path $p); Set-Content -Path $p -Value $t -Encoding UTF8; Write-Host "✔ wrote $p" }

# Paths
$basePath = "src/_includes/layouts/base.njk"
$heroPath = "src/_includes/components/hero.njk"
$cssPath  = "src/assets/css/site.css"

# 1) Update base.njk: load Playfair Display for headings (keep Inter for body)
if (Test-Path $basePath) {
  $base = Get-Content $basePath -Raw
  Backup $basePath

  # Replace Google Fonts link block
  $base = $base -replace '(?s)<link href="https://fonts\.googleapis\.com/.*?rel="stylesheet">\s*<link rel="stylesheet" href="/assets/css/site\.css">',
  '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=Playfair+Display:wght@500;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/css/site.css">'

  Set-Content -Path $basePath -Value $base -Encoding UTF8
  Write-Host "✔ updated fonts in $basePath"
} else {
  Write-Host "⚠️  $basePath not found (skipping fonts)."
}

# 2) Hero partial: large background photo, watermark, overlapping intro card
$heroNJK = @'
{# Hero accepts an optional image path via page or site metadata #}
{# 1) Page-level:  page.heroImage  (front matter)
   2) Site-level:  metadata.heroImage (src/_data/metadata.json)
   3) Fallback:    /assets/img/hero-quixote.jpg
#}
{% set heroImg = page.heroImage or metadata.heroImage or "/assets/img/hero-quixote.jpg" %}

<section class="hero hero--quixote" style="--hero-img: url('{{ heroImg }}');">
  <div class="hero__media" aria-hidden="true"></div>
  <div class="hero__inner">
    <div class="hero__watermark" aria-hidden="true">Quixotic</div>

    <div class="hero__intro">
      <h1 class="hero__title">{{ metadata.title or "Quixotic" }}</h1>
      {% if metadata.description %}
        <p class="hero__tag">{{ metadata.description }}</p>
      {% else %}
        <p class="hero__tag">Research notes, analyses, and references — curated with care.</p>
      {% endif %}
    </div>
  </div>
</section>
'@
Write-Text $heroPath $heroNJK

# 3) CSS: add Playfair headings, hero image, watermark + overlapping intro
$cssAdd = @'
/* ===== Royal typography (headings) ===== */
h1,h2,h3,.card__title,.hero__title{
  font-family: "Playfair Display", Georgia, "Times New Roman", serif;
  letter-spacing:.01em;
}

/* ===== Quixote hero (transparent overlay, watermark, overlap card) ===== */
.hero--quixote{
  position:relative; margin:0 0 2.25rem;
  border-bottom:1px solid var(--hairline);
  /* subtle parchment base remains visible through overlay */
  background: var(--bg);
}
.hero--quixote .hero__media{
  position:absolute; inset:0;
  background-image:
    linear-gradient(to bottom, rgba(128,0,32,.50), rgba(128,0,32,0.15) 55%, rgba(128,0,32,0.00)),
    var(--hero-img);
  background-size:cover; background-position:center 30%;
  filter:saturate(0.9) contrast(0.95);
}
.hero--quixote .hero__inner{
  position:relative; max-width:1100px; margin:0 auto; padding:3.75rem 1rem 5.5rem;
}
.hero__watermark{
  position:absolute; inset:auto 1rem -1.2rem auto;
  font-family:"Playfair Display", Georgia, serif; font-weight:700;
  font-size: clamp(3.5rem, 10vw, 8rem);
  line-height:.9;
  color: rgba(0,0,0,0.06);                  /* subtle, not black */
  text-transform:capitalize;
  pointer-events:none; user-select:none;
  mix-blend-mode:multiply;                   /* blends into parchment */
}
html[data-theme="dark"] .hero__watermark{
  color: rgba(255,255,255,0.06);
  mix-blend-mode:screen;
}

.hero__intro{
  position:relative;
  width:min(720px, 92vw);
  margin:0;
  padding:1.1rem 1.2rem 1.2rem;
  background: color-mix(in srgb, var(--bg-soft) 88%, #fff 12%);  /* soft card on top of image */
  border:1px solid var(--hairline);
  border-radius:14px;
  box-shadow: 0 10px 28px rgba(0,0,0,.08);
}
.hero__title{ margin:0 0 .35rem; font-weight:700; }
.hero__tag{ margin:.2rem 0 0; color:var(--muted); max-width:70ch }

/* tighter spacing on narrow screens */
@media (max-width: 720px){
  .hero--quixote .hero__inner{ padding:2.75rem 1rem 4.25rem; }
  .hero__intro{ padding: .9rem 1rem 1rem }
  .hero__watermark{ right:.5rem; bottom:-.9rem; }
}
'@
if (Test-Path $cssPath) {
  Backup $cssPath
  Add-Content -Path $cssPath -Value $cssAdd
  Write-Host "✔ appended hero + type CSS to $cssPath"
} else {
  Write-Host "⚠️  $cssPath not found. Create it first, then re-run."
}

Write-Host "`n✅ Done."
Write-Host "Next:"
Write-Host "  1) Add your hero image at: src/assets/img/hero-quixote.jpg  (or set metadata.heroImage)"
Write-Host "  2) Run: npx @11ty/eleventy --serve"
Write-Host "  3) Open / — you should see a large Quixote hero, watermark, and intro card."
