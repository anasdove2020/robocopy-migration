# ============================================
# Script Name : Migrate-Files.ps1
# Purpose     : Migrate files using Robocopy while excluding listed files/folders
# Author      : Choirul Anas
# Version     : 1.0
# ============================================
# Description :
# - Validates source, target, and exclude paths (early exit on first failure)
# - Reads exclude list from CSV
# - Executes Robocopy with exclusion logic
# - Logs results and returns explicit exit codes:
#     0 = Success
#     1 = Validation failed (first failure)
#     2 = CSV read failed
#     3 = Robocopy failed
# ============================================

param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,                       # Source location of files

    [Parameter(Mandatory = $true)]
    [string]$TargetPath,                       # Target location for migration

    [Parameter(Mandatory = $true)]
    [string]$ExcludeCsvPath,                   # CSV file containing excluded files/folders

    [string]$OutputCsv = ".\MigrationResult.csv",  # Output CSV log file
    [int]$StartRow = 2                             # Starting row number (default: 2 if first row is header)
)

# ============================================
# HEADER INFO
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "     FILE MIGRATION UTILITY (ROBOCOPY)      " -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host " Source Path       : $SourcePath"
Write-Host " Target Path       : $TargetPath"
Write-Host " Exclude List Path : $ExcludeCsvPath"
Write-Host " Output CSV        : $OutputCsv"
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

# ============================================
# 1. VALIDATE SOURCE PATH (early exit on failure)
# ============================================
Write-Host "[VALIDATION] Checking source path..." -ForegroundColor Cyan
if (!(Test-Path $SourcePath)) {
    Write-Host "[ERROR] Source path not found: $SourcePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Validation failed (source). Please fix the issue and re-run the script." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[OK] Source path exists." -ForegroundColor Green
}

# ============================================
# 2. VALIDATE TARGET PATH (early exit on failure — no auto-create)
# ============================================
Write-Host "[VALIDATION] Checking target path..." -ForegroundColor Cyan
if (!(Test-Path $TargetPath)) {
    Write-Host "[ERROR] Target path not found: $TargetPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Validation failed (target). Target directory must already exist." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[OK] Target path exists." -ForegroundColor Green
}

# ============================================
# 3. VALIDATE EXCLUDE CSV PATH (early exit on failure)
# ============================================
Write-Host "[VALIDATION] Checking exclude CSV path..." -ForegroundColor Cyan
if (!(Test-Path $ExcludeCsvPath)) {
    Write-Host "[ERROR] Exclude CSV file not found: $ExcludeCsvPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Validation failed (exclude CSV). Please provide a valid CSV and re-run the script." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[OK] Exclude CSV file found." -ForegroundColor Green
}

Write-Host ""
Write-Host "All validations passed. Proceeding..." -ForegroundColor Green

# ============================================
# 4. READ EXCLUDE LIST FROM CSV
# ============================================
Write-Host ""
Write-Host "Reading exclude list..." -ForegroundColor Cyan
try {
    $excludeList = Import-Csv -Path $ExcludeCsvPath | Select-Object -Skip ($StartRow - 1)
    $excludedPaths = $excludeList | ForEach-Object { $_.Path }
    Write-Host "Total items to exclude: $($excludedPaths.Count)" -ForegroundColor Yellow
} catch {
    Write-Host "[ERROR] Failed to read Exclude CSV: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

# Create temporary exclude file
$tempExcludeFile = ".\ExcludeTemp.txt"
try {
    $excludedPaths | Out-File -FilePath $tempExcludeFile -Encoding ASCII -Force
    Write-Host "[OK] Temporary exclude file created: $tempExcludeFile" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to write temporary exclude file: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

# ============================================
# 5. EXECUTE ROBOCOPY
# ============================================
Write-Host ""
Write-Host "============== MIGRATING... =================" -ForegroundColor Cyan

$logFile = ".\Robocopy-log.txt"
$robocopyCmd = "robocopy `"$SourcePath`" `"$TargetPath`" /E /MOV /COPY:DATSO /R:1 /W:1 /XD `"$tempExcludeFile`" /XF `"$tempExcludeFile`" /TEE /LOG+:`"$logFile`""

Write-Host "Command: $robocopyCmd" -ForegroundColor DarkGray

try {
    Invoke-Expression $robocopyCmd
    # Robocopy exit codes: 0–7 = success/warnings, >=8 = failure
    if ($LASTEXITCODE -ge 8) {
        Write-Host ""
        Write-Host "[ERROR] Robocopy encountered a failure (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Remove-Item $tempExcludeFile -Force -ErrorAction SilentlyContinue
        exit 3
    } else {
        Write-Host ""
        Write-Host "[OK] Robocopy completed successfully (exit code: $LASTEXITCODE)" -ForegroundColor Green
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Robocopy execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item $tempExcludeFile -Force -ErrorAction SilentlyContinue
    exit 3
}

# ============================================
# 6. RECORD MIGRATION RESULTS
# ============================================
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if (Test-Path $logFile) {
    try {
        $lines = Get-Content $logFile -ErrorAction SilentlyContinue
        $results = @()
        foreach ($line in $lines) {
            if ($line -match "^(.*?)(New File|Copied|Failed|Extra File|Older)$") {
                $results += [PSCustomObject]@{
                    Timestamp = $timestamp
                    Message   = $line
                }
            }
        }

        if ($results.Count -gt 0) {
            $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Append
            Write-Host "[OK] Migration results saved to: $OutputCsv" -ForegroundColor Green
        } else {
            Write-Host "[INFO] No significant file operations detected in log." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to parse or save migration results: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] Log file not found. Robocopy may have failed." -ForegroundColor Red
}

# ============================================
# 7. CLEANUP
# ============================================
Remove-Item $tempExcludeFile -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Migration completed at $timestamp" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow

exit 0
