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
# 1️. VALIDATION
# ============================================
if (!(Test-Path $TargetPath)) {
    Write-Host "Target path not found: $TargetPath" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $ListToMovePath)) {
    Write-Host "File list not found: $ListToMovePath" -ForegroundColor Red
    exit 1
}

# ============================================
# 2️. READ FILE LIST
# ============================================
$allLines = Get-Content -Path $ListToMovePath | Where-Object { $_.Trim() -ne "" }

if ($allLines.Count -eq 0) {
    Write-Host "No paths found in file list. Nothing to move." -ForegroundColor Yellow
    exit 0
}

$lines = $allLines | Select-Object -Skip ($StartFromLine - 1)

Write-Host "===============  MOVING $($lines.Count) file(s) ===============" -ForegroundColor Cyan

# ============================================
# 3️. PROCESS EACH FILE
# ============================================
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$results = @()

$index = $StartFromLine - 1

foreach ($filePath in $lines) {
    $index = $index + 1

    $filePath = $filePath.Trim('"').Trim()

    if (!(Test-Path $filePath)) {
        Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to file not found." -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "ERROR"
            Line        = $index
            Source      = $filePath
            Destination = ""
            Message     = "File not found."
        }
        continue
    }

    $item = Get-Item $filePath
    if ($item.PSIsContainer -eq $true) {
        Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to folder detected (only files are allowed)." -ForegroundColor DarkYellow
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "SKIPPED"
            Line        = $index
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

        $exitCode = $LASTEXITCODE

        if ($exitCode -ge 8) {
            Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to exit Code = $exitCode." -ForegroundColor Red
            $results += [PSCustomObject]@{
                Timestamp   = $timestamp
                Status      = "ERROR"
                Line        = $index
                Source      = $filePath
                Destination = $destinationPath
                Message     = "Exit Code = $exitCode."
            }
        } else {
            if (Test-Path $filePath) {
                Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to file is locked or currently open in another program." -ForegroundColor Red

                if (Test-Path -Path $destinationPath) {
                    Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue
                }

                $results += [PSCustomObject]@{
                    Timestamp   = $timestamp
                    Status      = "ERROR"
                    Line        = $index
                    Source      = $filePath
                    Destination = $destinationPath
                    Message     = "File is locked or currently open in another program."
                }
            } else {
                if (Test-Path $destinationPath) {
                    Write-Host "[Line-$index] [$timestamp] [SUCCESS] File [$filePath] moved sucessfully to [$destinationPath]." -ForegroundColor Green
                    $results += [PSCustomObject]@{
                        Timestamp   = $timestamp
                        Status      = "SUCCESS"
                        Line        = $index
                        Source      = $filePath
                        Destination = $destinationPath
                        Message     = "File moved successfully."
                    }
                }
                else {
                    Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to robocopy failed or target not created." -ForegroundColor Red
                    $results += [PSCustomObject]@{
                        Timestamp   = $timestamp
                        Status      = "ERROR"
                        Line        = $index
                        Source      = $filePath
                        Destination = $destinationPath
                        Message     = "Robocopy failed or target not created."
                    }
                }
            }
        }
    }
    catch {
        Write-Host "[Line-$index] [$timestamp] [ERROR] Failed to move [$filePath] due to exception message [$($_.Exception.Message)]" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Timestamp   = $timestamp
            Status      = "ERROR"
            Line        = $index
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
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Process completed at $timestamp" -ForegroundColor Green
Write-Host "Result saved to: $outputCsv" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
