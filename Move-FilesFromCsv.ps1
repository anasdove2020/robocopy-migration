# ============================================
# Script Name : Move-FilesFromCsv.ps1
# Purpose     : Move files or folders listed in a CSV file to a target directory
#               while preserving their original folder structure
# Author      : Choirul Anas
# ============================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,                     # Destination folder

    [Parameter(Mandatory = $true)]
    [string]$ExcludeCsvPath                  # CSV file containing paths to move (column: Path)
)

# ============================================
# HEADER
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " MOVE FILES FROM CSV (KEEP FOLDER STRUCTURE)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1️⃣ VALIDATION
# ============================================
Write-Host "Validating target path..."
if (!(Test-Path $TargetPath)) {
    Write-Host "Target path not found: $TargetPath" -ForegroundColor Red
    exit 1
}

Write-Host "Validating CSV file..."
if (!(Test-Path $ExcludeCsvPath)) {
    Write-Host "CSV file not found: $ExcludeCsvPath" -ForegroundColor Red
    exit 1
}

# ============================================
# 2️⃣ READ CSV AND PREPARE OUTPUT
# ============================================
Write-Host "Reading file list from CSV..."
$items = Import-Csv -Path $ExcludeCsvPath

if ($items.Count -eq 0) {
    Write-Host "No data found in CSV. Nothing to move." -ForegroundColor Yellow
    exit 0
}

$outputCsv = ".\MoveResult.csv"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$results = @()

# ============================================
# 3️⃣ PROCESS EACH ITEM
# ============================================
Write-Host ""
Write-Host "=============== START MOVING ===============" -ForegroundColor Cyan

foreach ($item in $items) {
    $path = $item.Path

    if (!(Test-Path $path)) {
        Write-Host "Not found: $path" -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            Timestamp = $timestamp
            Path      = $path
            Status    = "Not Found"
        }
        continue
    }

    try {
        # Get the drive root (e.g., D:\)
        $driveRoot = Split-Path $path -Qualifier

        # Get relative path (everything after the drive root)
        $relativePath = $path.Substring($driveRoot.Length).TrimStart('\')

        # Construct destination preserving full folder structure
        $destination = Join-Path $TargetPath $relativePath

        # Ensure parent folder exists
        $parentDir = Split-Path $destination -Parent
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Move the file/folder
        Move-Item -Path $path -Destination $destination -Force

        Write-Host "Moved: $path -> $destination" -ForegroundColor Green
        $results += [PSCustomObject]@{
            Timestamp = $timestamp
            Path      = $path
            Status    = "Moved"
        }
    }
    catch {
        Write-Host "Error moving $path : $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp = $timestamp
            Path      = $path
            Status    = "Error: $($_.Exception.Message)"
        }
    }
}

# ============================================
# 4️⃣ WRITE RESULT
# ============================================
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Append
Write-Host ""
Write-Host "Migration completed at $timestamp" -ForegroundColor Cyan
Write-Host "Result saved to: $outputCsv" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
