param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$extendsRx = [regex]::new('{%\s*extends\s*["''](?<tpl>[^"'']+)["'']\s*%}', 'Singleline')
$blockRx   = [regex]::new('{%\s*block\s+content\s*%}(?<inner>.*?){%\s*endblock\s*%}', 'Singleline')
$frontRx   = [regex]::new('^(?<fm>---\s*\r?\n.*?\r?\n---\s*\r?\n)', 'Singleline')
$layoutRx  = [regex]::new('^\s*layout\s*:\s*(?<val>.+?)\s*$', 'Multiline')

$changed = 0; $scanned = 0

Get-ChildItem -Path $Path -Recurse -Include *.njk | ForEach-Object {
  $file = $_.FullName
  $text = Get-Content -Raw -LiteralPath $file
  $scanned++

  $hasExtends = $extendsRx.IsMatch($text)
  if (-not $hasExtends) { return }

  $hasFM = $false
  if ($frontRx.IsMatch($text)) {
    $fm = $frontRx.Match($text).Groups['fm'].Value
    $hasFM = $layoutRx.IsMatch($fm)
  }
  if (-not $hasFM) { return }  # only fix files that have BOTH

  $fmMatch = $frontRx.Match($text)
  $fm   = $fmMatch.Groups['fm'].Value
  $body = $text.Substring($fmMatch.Length)

  # remove extends
  $body2 = $extendsRx.Replace($body, '')

  # unwrap block content if present
  if ($blockRx.IsMatch($body2)) {
    $inner = ($blockRx.Match($body2).Groups['inner'].Value).Trim()
    $body2 = $blockRx.Replace($body2, $inner, 1)
  }
  $body2 = $body2.TrimStart()

  $newText = $fm + $body2

  if ($DryRun) { Write-Host "[DRY RUN] Would fix:" $file; return }

  Copy-Item -LiteralPath $file -Destination ($file + ".bak") -Force
  Set-Content -LiteralPath $file -Value $newText -NoNewline
  Write-Host "Fixed:" $file
  $changed++
}

Write-Host "`nScanned: $scanned file(s). Fixed: $changed file(s)." -ForegroundColor Cyan