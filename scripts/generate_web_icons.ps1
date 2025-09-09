param(
  [string]$Source = "../web/icons/favicon.png"
)
# Generates 192x192, 512x512 normal and maskable icons from the favicon.
# Requires ImageMagick 'magick' command installed and in PATH.

$ErrorActionPreference = 'Stop'

if (!(Test-Path $Source)) { throw "Source image not found: $Source" }

$webIconsDir = Resolve-Path "../web/icons" | Select-Object -ExpandProperty Path

$targets = @(
  @{ Name = 'Icon-192.png'; Size = 192 },
  @{ Name = 'Icon-512.png'; Size = 512 },
  @{ Name = 'Icon-maskable-192.png'; Size = 192 },
  @{ Name = 'Icon-maskable-512.png'; Size = 512 }
)

function Get-MagickCmd {
  if (Get-Command magick -ErrorAction SilentlyContinue) { return 'magick' }
  $possible = @(
    "$Env:ProgramFiles\ImageMagick*\magick.exe",
    "$Env:ProgramFiles\ImageMagick*\magick.exe",
    "$Env:ProgramFiles(x86)\ImageMagick*\magick.exe"
  ) | ForEach-Object { Get-Item $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
  if ($possible) { return $possible.FullName }
  throw 'ImageMagick (magick) not found in PATH or standard locations.'
}

$magick = Get-MagickCmd

foreach ($t in $targets) {
  $out = Join-Path $webIconsDir $t.Name
  & $magick convert $Source -resize "$($t.Size)x$($t.Size)" -background none -gravity center -extent "$($t.Size)x$($t.Size)" PNG32:$out
  Write-Host "Generated $out"
}

Write-Host "All icons generated."
