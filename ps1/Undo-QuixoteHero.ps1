param(
  [string]$SrcRoot = ".\src",
  [string]$CssPath = ".\src\assets\css\main.css"
)

$ErrorActionPreference = "Stop"

function Restore-FromBak($path) {
  $bak = "$path.bak"
  if (Test-Path $bak) {
    Write-Host "Restoring from backup: $path"
    if (Test-Path $path) { Remove-Item -LiteralPath $path -Force }
    Rename-Item -LiteralPath $bak -NewName (Split-Path -Leaf $path) -Force
    return $true
  }
  return $false
}

# --- 1) Undo CSS injection ---
if (-not (Restore-FromBak $CssPath)) {
  if (Test-Path $CssPath) {
    $css = Get-Content -Raw -LiteralPath $CssPath

    # Remove the exact watermark block (comment + .hero + .hero::before)
    $css2 = $css -replace '(?s)/\*\s*Quixote watermark\s*\*/.*?}\s*}', ''

    if ($css2 -ne $css) {
      Write-Host "Removed Quixote watermark CSS from $CssPath"
      Set-Content -LiteralPath $CssPath -Value $css2 -NoNewline
    } else {
      Write-Host "No watermark CSS found in $CssPath"
    }
  } else {
    Write-Host "CSS file not found: $CssPath"
  }
}

# --- 2) Undo hero include style mutation ---
# Try to locate components/hero.njk
$heroFile = Get-ChildItem -Path $SrcRoot -Recurse -File -Filter "hero.njk" |
  Where-Object { $_.FullName -match "components[\\/]+hero\.njk$" } |
  Select-Object -First 1
if (-not $heroFile) {
  $heroFile = Get-ChildItem -Path $SrcRoot -Recurse -File -Filter "hero.njk" | Select-Object -First 1
}
if ($heroFile) {
  $heroPath = $heroFile.FullName

  if (-not (Restore-FromBak $heroPath)) {
    $html = Get-Content -Raw -LiteralPath $heroPath

    # Find opening <section ... class="...hero...">
    $sectionRx = [regex]'<section\s+([^>]*\bclass\s*=\s*"[^"]*\bhero\b[^"]*"[^>]*)>'
    if ($sectionRx.IsMatch($html)) {
      $openTag = $sectionRx.Match($html).Groups[0].Value

      # Remove --hero-img from style attr; drop style attr if empty afterwards
      $newOpen = $openTag
      if ($openTag -match 'style\s*=\s*"([^"]*)"') {
        $style = $Matches[1]
        $style2 = $style -replace '\s*;?\s*--hero-img\s*:\s*url\([^)]+\)\s*;?', ''  # remove prop
        $style2 = $style2 -replace ';;+', ';'                                      # collapse
        $style2 = $style2.Trim().Trim(';').Trim()

        if ([string]::IsNullOrWhiteSpace($style2)) {
          $newOpen = $openTag -replace '\sstyle\s*=\s*"[^"]*"', ''                  # drop style attr
        } else {
          $styleQuoted = ($openTag -replace 'style\s*=\s*"[^"]*"', ('style="' + $style2 + '"'))
          if ($styleQuoted -ne $openTag) { $newOpen = $styleQuoted }
        }
      }

      if ($newOpen -ne $openTag) {
        Write-Host "Removed --hero-img from $heroPath"
        $html = $html.Replace($openTag, $newOpen)
        Set-Content -LiteralPath $heroPath -Value $html -NoNewline
      } else {
        Write-Host "No --hero-img style found in $heroPath"
      }
    } else {
      Write-Host "Could not find a <section ... class=""... hero ...""> in $heroPath"
    }
  }
} else {
  Write-Host "Could not locate components\hero.njk under $SrcRoot"
}

Write-Host "Undo complete."