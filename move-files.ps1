# ============================================
# Script Name : Move-Files.ps1
# Purpose     : Move files listed in a CSV file to a target directory
#               while preserving their original folder structure.
#               Uses Robocopy for performance and reliability.
# Author      : Choirul Anas
# ============================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,                    # Destination folder

    [Parameter(Mandatory = $true)]
    [string]$ListToMovePath,                # CSV or TXT file containing file paths (one per line)

    [Parameter(Mandatory = $true)]
    [int]$StartFromLine = 1                 # Line number to start reading from (default: 1, meaning start from the first line)
)

# ============================================
# HEADER
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " MOVE FILES USING ROBOCOPY (FILES ONLY)" -ForegroundColor Cyan
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

Write-Host "Validating list file..."
if (!(Test-Path $ListToMovePath)) {
    Write-Host "File list not found: $ListToMovePath" -ForegroundColor Red
    exit 1
}

# ============================================
# 2️. READ FILE LIST
# ============================================
Write-Host "Reading file list..."
$allLines = Get-Content -Path $ListToMovePath | Where-Object { $_.Trim() -ne "" }

if ($allLines.Count -eq 0) {
    Write-Host "No paths found in file list. Nothing to move." -ForegroundColor Yellow
    exit 0
}

if ($allLines[0] -match '^(Path|File|Source)') {
    $allLines = $allLines | Select-Object -Skip 1
}

if ($StartFromLine -gt 1) {
    Write-Host "Skipping first $($StartFromLine - 1) line(s)..." -ForegroundColor DarkYellow
    $lines = $allLines | Select-Object -Skip ($StartFromLine - 1)
} else {
    $lines = $allLines
}

Write-Host "Found $($lines.Count) file(s) to move."
Write-Host ""
Write-Host "=============== START MOVING ===============" -ForegroundColor Cyan

# ============================================
# 3️. PROCESS EACH FILE
# ============================================
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$results = @()

foreach ($filePath in $lines) {
    $filePath = $filePath.Trim('"').Trim()

    if (!(Test-Path $filePath)) {
        Write-Host "[$timestamp] [ERROR] File not found: $filePath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "ERROR"
            Source      = $filePath
            Destination = ""
            Message     = "File not found."
        }
        continue
    }

    $item = Get-Item $filePath
    if ($item.PSIsContainer -eq $true) {
        Write-Host "[$timestamp] [SKIP] Folder detected, skipping: $filePath" -ForegroundColor DarkYellow
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "SKIPPED"
            Source      = $filePath
            Destination = ""
            Message     = "Folder detected. Only files are allowed."
        }
        continue
    }

    try {
        # Extract relative path after drive root
        $driveRoot = Split-Path $filePath -Qualifier
        $relativePath = $filePath.Substring($driveRoot.Length).TrimStart('\')

        # Construct destination path preserving structure
        $destinationPath = Join-Path $TargetPath $relativePath
        $destinationDir = Split-Path $destinationPath -Parent

        # Ensure target directory exists
        if (!(Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        # Robocopy command
        $sourceDir = Split-Path $filePath -Parent
        $fileName = Split-Path $filePath -Leaf
        $robocopyCmd = "robocopy `"$sourceDir`" `"$destinationDir`" `"$fileName`" /MOV /COPYALL /R:1 /W:1 /MT:16 /NFL /NDL /NP /NJH /NJS"

        cmd /c $robocopyCmd | Out-Null

        Write-Host "Exit Code = $LASTEXITCODE"

        if (Test-Path $destinationPath) {
            Write-Host "[$timestamp] [SUCCESS] $filePath -> $destinationPath" -ForegroundColor Green
            $results += [PSCustomObject]@{
                LineNumber  = ""
                Timestamp   = $timestamp
                Status      = "SUCCESS"
                Source      = $filePath
                Destination = $destinationPath
                Message     = "File moved successfully."
            }
        }
        else {
            Write-Host "[$timestamp] [ERROR] Failed to move: $filePath" -ForegroundColor Red
            $results += [PSCustomObject]@{
                LineNumber  = ""
                Timestamp   = $timestamp
                Status      = "ERROR"
                Source      = $filePath
                Destination = $destinationPath
                Message     = "Robocopy failed or target not created."
            }
        }
    }
    catch {
        Write-Host "[$timestamp] [ERROR] Exception on file: $filePath" -ForegroundColor Red
        Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "ERROR"
            Source      = $filePath
            Destination = ""
            Message     = $_.Exception.Message
        }
    }
}

# ============================================
# 4️. SAVE RESULT TO CSV
# ============================================
$timestampForFile = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputCsv = ".\MoveResult-$timestampForFile.csv"

$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Process completed at $timestamp" -ForegroundColor Cyan
Write-Host "Result saved to: $outputCsv" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
