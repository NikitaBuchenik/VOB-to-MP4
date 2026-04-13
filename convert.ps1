# convert.ps1 - simple converter
param([string]$FolderPath)

if (-not $FolderPath) {
    Write-Host "Usage: .\convert.ps1 'C:\path\to\folder'" -ForegroundColor Yellow
    exit
}

# Find FFmpeg
$ffmpegPath = $null
$searchPaths = @(
    "$env:USERPROFILE\AppData\Roaming\Python\Python314\site-packages\imageio_ffmpeg\binaries",
    "$env:USERPROFILE\AppData\Roaming\Python\Python314\Scripts"
)

foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        $found = Get-ChildItem -Path $searchPath -Filter "ffmpeg*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $ffmpegPath = $found.FullName
            break
        }
    }
}

if (-not $ffmpegPath) {
    Write-Host "FFmpeg not found!" -ForegroundColor Red
    Write-Host "Install: pip install imageio-ffmpeg" -ForegroundColor Yellow
    Read-Host "Press Enter"
    exit
}

Write-Host "FFmpeg: $ffmpegPath" -ForegroundColor Green

# Check VIDEO_TS folder
$videoTs = Join-Path $FolderPath "VIDEO_TS"
if (-not (Test-Path $videoTs)) {
    Write-Host "VIDEO_TS folder not found!" -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}

# Go to VIDEO_TS
cd $videoTs

# Find VOB files
$vobFiles = Get-ChildItem -Filter "*.VOB" | Where-Object { $_.Name -notlike "*0.VOB" }

if ($vobFiles.Count -eq 0) {
    Write-Host "No VOB files found!" -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}

# Output file name
$movieName = Split-Path $FolderPath -Leaf
$outputFile = Join-Path $FolderPath "$movieName.mp4"

Write-Host "Movie: $movieName" -ForegroundColor Cyan
Write-Host "Files: $($vobFiles.Count)" -ForegroundColor Cyan
Write-Host "Output: $outputFile" -ForegroundColor Cyan
Write-Host ""

# Create file list
$fileList = ($vobFiles.FullName) -join "|"

# Confirmation
$confirm = Read-Host "Start conversion? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Converting... This may take a while..." -ForegroundColor Green
Write-Host ""

# Run FFmpeg
& $ffmpegPath -i "concat:$fileList" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k -y $outputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "DONE!" -ForegroundColor Green
    if (Test-Path $outputFile) {
        $size = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
        Write-Host "Size: $size MB" -ForegroundColor Cyan
        Write-Host "Path: $outputFile" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "ERROR!" -ForegroundColor Red
}

Read-Host "Press Enter"