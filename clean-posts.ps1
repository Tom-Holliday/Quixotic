# clean-posts.ps1
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\clean-posts.ps1
#   powershell -ExecutionPolicy Bypass -File .\clean-posts.ps1 -All     # remove ALL posts under src/posts
#   powershell -ExecutionPolicy Bypass -File .\clean-posts.ps1 -Names "foo.md","bar.md"

param(
  [switch]$All,
  [string[]]$Names
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$postsDir = "src/posts"
$sitePostsDir = "_site/posts"
$debugSrc = "src/debug.njk"
$debugOut = "_site/debug"

# --- Helper: backup folder ---
$stamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
$backupRoot = "backups/posts-$stamp"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

function Move-IfExists($path, $destDir) {
  if (Test-Path $path) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Move-Item -Force -Path $path -Destination $destDir
    Write-Host "→ Moved $path -> $destDir"
  }
}

# --- Collect targets ---
if ($All) {
  if (-not (Test-Path $postsDir)) { Write-Host "No $postsDir directory found. Skipping."; exit 0 }
  $postFiles = Get-ChildItem -Path $postsDir -File -Include *.md -Recurse
} elseif ($Names -and $Names.Count -gt 0) {
  $postFiles = foreach ($n in $Names) {
    $p = Join-Path $postsDir $n
    if (Test-Path $p) { Get-Item $p } else { Write-Host "(!) Not found: $p" }
  }
} else {
  # Default: remove the sample posts we created during setup
  $candidates = @(
    "debug-post.md",
    "Hello World.md",
    "First Blog Post.md",
    "First Blog Post/index.md" # just in case someone nested
  )
  $postFiles = foreach ($c in $candidates) {
    $p = Join-Path $postsDir $c
    if (Test-Path $p) { Get-Item $p }
  }
}

if (-not $postFiles -or $postFiles.Count -eq 0) {
  Write-Host "No matching post files to remove. (Use -All or -Names to target others.)"
} else {
  Write-Host "Backing up and removing the following post files:"
  $postFiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
  foreach ($f in $postFiles) {
    $dest = Join-Path $backupRoot "src-posts"
    Move-IfExists $f.FullName $dest
  }
}

# --- Remove built outputs for those posts (best-effort) ---
if (Test-Path $sitePostsDir) {
  foreach ($f in $postFiles) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)

    # Possible output folder names (Eleventy can use spaces or slugs depending on permalinks)
    $candidates = @(
      (Join-Path $sitePostsDir $base),
      (Join-Path $sitePostsDir ($base -replace '\s+','-').ToLower()),
      (Join-Path $sitePostsDir ($base -replace '\s+',' '))
    ) | Select-Object -Unique

    foreach ($cand in $candidates) {
      if (Test-Path $cand) {
        $dest = Join-Path $backupRoot "_site-posts"
        Move-IfExists $cand $dest
      }
    }
  }
}

# --- Remove the debug page we added ---
if (Test-Path $debugSrc) {
  Move-IfExists $debugSrc (Join-Path $backupRoot "src")
}
if (Test-Path $debugOut) {
  Move-IfExists $debugOut (Join-Path $backupRoot "_site")
}

# --- Optional: clean stray .bak files created earlier (base/index) ---
$bakList = Get-ChildItem -Recurse -File -Include "*.bak.*" -ErrorAction SilentlyContinue
if ($bakList) {
  $dest = Join-Path $backupRoot "bak"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($b in $bakList) { Move-IfExists $b.FullName $dest }
}

Write-Host "`n✅ Done. Backups are in $backupRoot"
Write-Host "Next:"
Write-Host "  • Create real posts in Netlify CMS (/admin) and publish."
Write-Host "  • Rebuild locally with: npx @11ty/eleventy --serve"
