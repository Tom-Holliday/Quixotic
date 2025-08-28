<#
Debug-StalePost.ps1
Finds why a deleted post still shows on the live blog.

What it does:
- Confirms Git state (branch, upstream, latest commit)
- Checks Decap (Netlify CMS) config for git-gateway + delete:true + branch
- Searches for the post by slug in `src/posts/` (both `slug.md` and `slug/index.md`)
- Ensures your listing template uses the "published" collection
- (Optional) Builds Eleventy and checks `_site` for stale files
- Prints next-step actions (Netlify rebuild / cache clear)

Usage:
  .\Debug-StalePost.ps1 -Slug "your-post-slug" -Build
  .\Debug-StalePost.ps1 -Slug "your-post-slug"
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Slug,
  [string]$PostsRoot = ".\src\posts",
  [string]$AdminConfig = ".\src\admin\config.yml",
  [string]$IncludesRoot = ".\src\_includes",
  [switch]$Build
)

$ErrorActionPreference = "Stop"

function Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# 1) Git status
Section "Git status"
try {
  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) { throw "Not a git repo." }

  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  $remote = (git remote get-url origin).Trim()
  Write-Host ("Branch: " + $branch)
  Write-Host ("Remote: " + $remote)

  git fetch --all --prune *> $null
  $localSHA  = (git rev-parse $branch).Trim()
  $remoteSHA = (git rev-parse origin/$branch).Trim()
  Write-Host ("Local  SHA: " + $localSHA)
  Write-Host ("Remote SHA: " + $remoteSHA)
  if ($localSHA -ne $remoteSHA) {
    Write-Warning "Local and remote differ. Push or pull to sync before debugging deploys."
  }
} catch { Write-Warning $_ }

# 2) Decap (Netlify CMS) config sanity
Section "Decap CMS config checks"
if (Test-Path $AdminConfig) {
  $y = Get-Content -Raw -LiteralPath $AdminConfig
  if ($y -match 'backend:\s*\r?\n\s*name:\s*git-gateway') {
    Write-Host "Backend: git-gateway ✔"
  } else {
    Write-Warning "Backend is NOT git-gateway. Check $AdminConfig (backend.name)."
  }
  if ($y -match 'branch:\s*main') {
    Write-Host "Backend branch: main ✔"
  } else {
    Write-Warning "Backend branch is not 'main'. Check $AdminConfig."
  }
  if ($y -match 'collections:\s*(?s).*name:\s*posts(?s).*delete:\s*true') {
    Write-Host "Posts collection allows delete ✔"
  } else {
    Write-Warning "Posts collection may not allow delete. Add `delete: true` under posts."
  }
} else {
  Write-Warning "CMS config not found: $AdminConfig"
}

# 3) Look for post files by slug
Section "Searching for post files"
$paths = @()
# Common patterns: /slug.md and /slug/index.md
$paths += Get-ChildItem -Recurse -LiteralPath $PostsRoot -Filter "$Slug.md" -File -ErrorAction SilentlyContinue
$paths += Get-ChildItem -Recurse -LiteralPath $PostsRoot -Filter "index.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq $Slug }

if ($paths.Count -gt 0) {
  Write-Warning "Found post files still present:"
  $paths | ForEach-Object { Write-Host " - $($_.FullName)" }
} else {
  Write-Host "No post files named '$Slug' found in $PostsRoot ✔"
}

# 4) Ensure listing uses published collection
Section "Listing template check"
$usePublished = $false
if (Test-Path $IncludesRoot) {
  $hits = Get-ChildItem -Recurse -LiteralPath $IncludesRoot -Include *.njk -File |
    Select-String -Pattern 'postsPublishedSorted' -SimpleMatch
  if ($hits) {
    $usePublished = $true
    Write-Host "Found 'postsPublishedSorted' in:" 
    $hits | ForEach-Object { Write-Host " - $($_.Path):$($_.LineNumber)" }
  } else {
    Write-Warning "Could not find 'postsPublishedSorted' in $IncludesRoot. Ensure your listing uses the published collection."
  }
} else {
  Write-Warning "Includes folder not found: $IncludesRoot"
}

# 5) Optional build + scan _site
if ($Build) {
  Section "Building Eleventy and scanning _site"
  try {
    & npx @11ty/eleventy *> $null
    if ($LASTEXITCODE -ne 0) { Write-Warning "Eleventy build returned an error." }
  } catch { Write-Warning $_ }

  $siteDir = ".\_site"
  if (Test-Path $siteDir) {
    $siteHits = Get-ChildItem -Recurse $siteDir -File |
      Where-Object { $_.Name -match $Slug -or (Select-String -Path $_.FullName -Pattern $Slug -SimpleMatch -ErrorAction SilentlyContinue) } |
      Select-Object -Unique FullName
    if ($siteHits) {
      Write-Warning "References to slug found in built site:"
      $siteHits | ForEach-Object { Write-Host " - $($_.FullName)" }
    } else {
      Write-Host "No references to slug found in _site ✔"
    }
  } else {
    Write-Warning "_site was not produced."
  }
}

# 6) Summary & next actions
Section "Next steps"
if ($paths.Count -gt 0) {
  Write-Host "Delete the file(s) above, then:"
  Write-Host "  git add -A"
  Write-Host "  git commit -m 'chore(posts): delete $Slug'"
  Write-Host "  git push"
} else {
  Write-Host "If the file is gone but still shows on Netlify:"
  Write-Host " - Check Netlify Deploys: latest commit SHA must match GitHub main"
  Write-Host " - Trigger: Deploys → Clear cache and deploy site"
  Write-Host " - Or force a rebuild:"
  Write-Host "     git commit --allow-empty -m 'chore: redeploy'"
  Write-Host "     git push"
  Write-Host "If using editorial_workflow, open /admin → Workflow → publish the deletion."
}
