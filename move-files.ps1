# ============================================
# Script Name : move-files.ps1
# Purpose     : Move files listed in a CSV file to a target directory
#               while preserving their original folder structure
# Author      : Choirul Anas
# ============================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,                     # Destination folder

    [Parameter(Mandatory = $true)]
    [string]$ListToMovePath                 # CSV file containing paths to move (column: Path)
)

# ============================================
# HEADER
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " MOVE FILES FROM CSV (FILES ONLY, KEEP STRUCTURE)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1️. VALIDATION
# ============================================
Write-Host "Validating target path..."
if (!(Test-Path $TargetPath)) {
    Write-Host "Target path not found: $TargetPath" -ForegroundColor Red
    exit 1
}

Write-Host "Validating List To Move file..."
if (!(Test-Path $ListToMovePath)) {
    Write-Host "CSV file not found: $ListToMovePath" -ForegroundColor Red
    exit 1
}

# ============================================
# 2️. READ CSV AND PREPARE OUTPUT
# ============================================
Write-Host "Reading file list from CSV..."
$items = Import-Csv -Path $ListToMovePath

if ($items.Count -eq 0) {
    Write-Host "No data found in CSV. Nothing to move." -ForegroundColor Yellow
    exit 0
}

$outputCsv = ".\MoveResult.csv"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$results = @()

# ============================================
# 3️. PROCESS EACH ITEM (FILES ONLY)
# ============================================
Write-Host ""
Write-Host "=============== START MOVING ===============" -ForegroundColor Cyan

foreach ($item in $items) {
    $path = $item.Path

    if (!(Test-Path $path)) {
        Write-Host "[$timestamp] [ WARNING ] File [$path] not found." -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "WARNING"
            Source      = $path
            Destination = ""
            Message     = "File not found."
        }
        continue
    }

    # Check if path is a folder
    $itemType = (Get-Item $path).PSIsContainer
    if ($itemType -eq $true) {
        Write-Host "[$timestamp] [ WARNING ] Folder detected, skipping [$path]." -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "WARNING"
            Source      = $path
            Destination = ""
            Message     = "Folder detected, only files are allowed."
        }
        continue
    }

    try {
        # Get drive root (e.g., D:\)
        $driveRoot = Split-Path $path -Qualifier

        # Get relative path (everything after drive root)
        $relativePath = $path.Substring($driveRoot.Length).TrimStart('\')

        # Construct destination path preserving structure
        $destination = Join-Path $TargetPath $relativePath

        # Ensure parent folder exists
        $parentDir = Split-Path $destination -Parent
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Move file
        Move-Item -Path $path -Destination $destination -Force

        Write-Host "[$timestamp] [  INFO   ] Success to move file from [$path] to [$destination]" -ForegroundColor Green
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "SUCCESS"
            Source      = $path
            Destination = $destination
            Message     = "File moved successfully."
        }
    }
    catch {
        Write-Host "[$timestamp] [ERROR] Failed to move file: [$path] to [$destination]." -ForegroundColor Red
        Write-Host "        Reason: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "ERROR"
            Source      = $path
            Destination = $destination
            Message     = $($_.Exception.Message)
        }
    }
}

# ============================================
# 4️. WRITE RESULT
# ============================================
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Append
Write-Host ""
Write-Host "Process completed at $timestamp" -ForegroundColor Cyan
Write-Host "Result saved to: $outputCsv" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
