param(
  [string]$SrcRoot = ".\src",
  [string]$CssPath = ".\src\assets\css\main.css",
  [switch]$NoServe
)

$ErrorActionPreference = "Stop"

function Backup-Once($path) {
  if (-not (Test-Path $path)) { return }
  $bak = "$path.bak"
  if (-not (Test-Path $bak)) { Copy-Item -LiteralPath $path -Destination $bak -Force }
}

# --- 2) Ensure watermark CSS exists ---
$cssBlock = @"
/* Quixote watermark */
.hero { position: relative; isolation: isolate; }
.hero::before {
  content: "";
  position: absolute;
  inset: 0;
  background-image: var(--hero-img, url('/assets/img/quixote.jpg'));
  background-size: cover;
  background-position: center;
  opacity: .12;
  filter: grayscale(35%);
  pointer-events: none;
  z-index: -1;
}
"@

if (-not (Test-Path $CssPath)) {
  # create folder/file if missing
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CssPath) | Out-Null
  Set-Content -Path $CssPath -Value ""
}

$cssText = Get-Content -Raw -LiteralPath $CssPath
if ($cssText -notmatch '\.hero::before\s*\{') {
  Write-Host "Adding watermark CSS to $CssPath"
  Backup-Once $CssPath
  Add-Content -LiteralPath $CssPath -Value "`r`n$cssBlock"
} else {
  Write-Host "Watermark CSS already present in $CssPath"
}

# --- 3) Update components/hero.njk to set --hero-img ---
# Try to locate components/hero.njk under src
$heroFile = Get-ChildItem -Path $SrcRoot -Recurse -File -Filter "hero.njk" |
  Where-Object { $_.FullName -match "components[\\/]+hero\.njk$" } |
  Select-Object -First 1

if (-not $heroFile) {
  # fallback: first hero.njk anywhere
  $heroFile = Get-ChildItem -Path $SrcRoot -Recurse -File -Filter "hero.njk" | Select-Object -First 1
}

if (-not $heroFile) {
  throw "Couldn't find components\hero.njk under $SrcRoot"
}

$heroPath = $heroFile.FullName
$heroText = Get-Content -Raw -LiteralPath $heroPath

# Regex to find opening <section class="...hero...">
$sectionRx = [regex]'<section\s+([^>]*\bclass\s*=\s*"[^"]*\bhero\b[^"]*"[^>]*)>'
if ($sectionRx.IsMatch($heroText)) {
  $openTag = $sectionRx.Match($heroText).Groups[0].Value
  # If style already contains --hero-img, do nothing; else add/merge style attr
  if ($openTag -notmatch '--hero-img') {
    $hasStyle = $openTag -match '\sstyle\s*='
    if ($hasStyle) {
      # Append to existing style
      $newOpen = $openTag -replace 'style\s*=\s*"([^"]*)"', { param($m) "style=`"$($m.Groups[1].Value); --hero-img: url('{{ metadata.heroImage }}');`"" }
    } else {
      # Insert new style attribute
      $newOpen = $openTag -replace '<section\s+', '<section style="--hero-img: url(''{{ metadata.heroImage }}'');" '
    }
    if ($newOpen -ne $openTag) {
      Write-Host "Updating $heroPath to set --hero-img"
      Backup-Once $heroPath
      $heroText = $heroText.Replace($openTag, $newOpen)
      Set-Content -LiteralPath $heroPath -Value $heroText -NoNewline
    }
  } else {
    Write-Host "--hero-img already configured in $heroPath"
  }
} else {
  throw "Could not find a <section ... class=""... hero ...""> opening tag in $heroPath"
}

# --- 4) Serve site (unless skipped) ---
if (-not $NoServe) {
  Write-Host "Starting Eleventy dev server..."
  & npx @11ty/eleventy --serve
} else {
  Write-Host "Skipping serve (NoServe set). Run: npx @11ty/eleventy --serve"
}