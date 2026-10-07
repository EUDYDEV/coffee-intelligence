# Turns a video into the frame sequence used by the cinematic home page.
# Usage:  powershell -File tools/make_sequence.ps1 -Video naissance.mp4 [-Frames 180] [-Width 1280] [-LiteWidth 720]
# Needs ffmpeg in PATH. Output goes to assets/sequence (frames f_0001.webp...) + manifest.json.
param(
  [Parameter(Mandatory = $true)][string]$Video,
  [int]$Frames = 180,
  [int]$Width = 1280,
  [int]$LiteWidth = 720
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\assets\sequence'
New-Item -ItemType Directory -Force $dir | Out-Null
Get-ChildItem $dir -Filter 'f_*.webp' | Remove-Item -Force
Get-ChildItem $dir -Filter 'l_*.webp' | Remove-Item -Force
$dur = [double](& ffprobe -v error -show_entries format=duration -of csv=p=0 $Video)
$fps = [math]::Round($Frames / $dur, 4)
& ffmpeg -y -i $Video -vf "fps=$fps,scale=${Width}:-2" -c:v libwebp -quality 72 (Join-Path $dir 'f_%04d.webp')
& ffmpeg -y -i $Video -vf "fps=$fps,scale=${LiteWidth}:-2" -c:v libwebp -quality 68 (Join-Path $dir 'l_%04d.webp')
$n = (Get-ChildItem $dir -Filter 'f_*.webp').Count
$manifest = [ordered]@{
  pattern  = 'assets/sequence/f_%04d.webp'
  frames   = $n
  aspect   = 1.7778
  lite     = [ordered]@{ pattern = 'assets/sequence/l_%04d.webp'; frames = $n }
  chapters = @(0.00, 0.05, 0.12, 0.25, 0.34, 0.42, 0.48, 0.58, 0.68, 0.74, 0.80, 0.86, 0.94)
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $dir 'manifest.json') -Encoding utf8
Write-Host "OK: $n frames (+ lite version for phones). Rebuild the app: flutter build web / apk."
