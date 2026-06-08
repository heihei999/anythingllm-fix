#Requires -Version 5.1
<#
.SYNOPSIS
    AnythingLLM Desktop Patcher - Applies bug fixes to the installed AnythingLLM Desktop app.

.DESCRIPTION
    This patcher extracts the app.asar archive, applies server-side fixes and frontend updates,
    then repacks the asar. The data directory is NOT modified.

.PARAMETER AsarPath
    Path to the app.asar file. Defaults to the standard Windows installation path.

.PARAMETER SkipFrontend
    Skip patching frontend assets (only patch server files).

.EXAMPLE
    .\patcher.ps1
    .\patcher.ps1 -AsarPath "C:\custom\path\app.asar"
    .\patcher.ps1 -SkipFrontend
#>

param(
    [string]$AsarPath = "$env:LOCALAPPDATA\Programs\AnythingLLM\resources\app.asar",
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PatchesDir = Join-Path $ScriptDir "patches"
$TempDir = Join-Path $env:TEMP "anythingllm-patcher-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Server files to patch
$ServerFiles = @(
    @{
        Source = Join-Path $PatchesDir "server\utils\chats\stream.js"
        Target = "server\utils\chats\stream.js"
    },
    @{
        Source = Join-Path $PatchesDir "server\utils\helpers\chat\responses.js"
        Target = "server\utils\helpers\chat\responses.js"
    }
)

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "  [ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [INFO] $Message" -ForegroundColor Yellow
}

function Get-FileSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-Item $Path).Length
        if ($size -gt 1MB) {
            return "{0:N2} MB" -f ($size / 1MB)
        } elseif ($size -gt 1KB) {
            return "{0:N2} KB" -f ($size / 1KB)
        } else {
            return "$size bytes"
        }
    }
    return "N/A"
}

function Test-NpxAvailable {
    try {
        $null = Get-Command npx -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-AsarModuleAvailable {
    try {
        $null = & npx asar --version 2>&1
        return $true
    } catch {
        return $false
    }
}

# ============================================================================
# Main Script
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AnythingLLM Desktop Patcher v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Validate inputs
Write-Status "[1/7] Validating inputs..."

if (-not (Test-Path $AsarPath)) {
    Write-Error "app.asar not found at: $AsarPath"
    Write-Info "Please provide the correct path using -AsarPath parameter"
    exit 1
}

if (-not (Test-Path $PatchesDir)) {
    Write-Error "Patches directory not found at: $PatchesDir"
    Write-Info "Make sure the patches folder is in the same directory as this script"
    exit 1
}

# Check for required server files
foreach ($file in $ServerFiles) {
    if (-not (Test-Path $file.Source)) {
        Write-Error "Missing patch file: $($file.Source)"
        exit 1
    }
}

if (-not $SkipFrontend) {
    $FrontendDir = Join-Path $PatchesDir "frontend"
    if (-not (Test-Path $FrontendDir)) {
        Write-Error "Frontend patches directory not found at: $FrontendDir"
        Write-Info "Use -SkipFrontend to skip frontend patching"
        exit 1
    }
}

# Check for npx
if (-not (Test-NpxAvailable)) {
    Write-Error "npx is not available. Please install Node.js first."
    exit 1
}

Write-Success "All inputs validated"

# Step 2: Create backup
Write-Status "[2/7] Creating backup..."

$BackupPath = "$AsarPath.bak"
if (Test-Path $BackupPath) {
    Write-Info "Backup already exists, keeping it: $BackupPath"
} else {
    Copy-Item $AsarPath $BackupPath -Force
    Write-Success "Backup created: $BackupPath"
}

# Step 3: Record original size
Write-Status "[3/7] Recording original asar size..."
$OriginalSize = Get-FileSize $AsarPath
Write-Info "Original asar size: $OriginalSize"

# Step 4: Extract asar
Write-Status "[4/7] Extracting asar archive..."

# Create temp directory
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    & npx asar extract $AsarPath $TempDir 2>&1 | Out-Null
    Write-Success "Extracted to: $TempDir"
} catch {
    Write-Error "Failed to extract asar: $_"
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Step 5: Apply server patches
Write-Status "[5/7] Applying server patches..."

foreach ($file in $ServerFiles) {
    $TargetPath = Join-Path $TempDir $file.Target
    
    # Ensure target directory exists
    $TargetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    # Copy the patched file
    Copy-Item $file.Source $TargetPath -Force
    Write-Success "Patched: $($file.Target)"
}

# Step 6: Apply frontend patches
if (-not $SkipFrontend) {
    Write-Status "[6/7] Applying frontend patches..."
    
    $FrontendSource = Join-Path $PatchesDir "frontend"
    $FrontendTarget = Join-Path $TempDir "server\public"
    
    # Ensure target directory exists
    if (-not (Test-Path $FrontendTarget)) {
        New-Item -ItemType Directory -Path $FrontendTarget -Force | Out-Null
    }
    
    # Copy all frontend files
    # First, copy root-level files
    $RootFiles = Get-ChildItem -Path $FrontendSource -File
    foreach ($file in $RootFiles) {
        $TargetFile = Join-Path $FrontendTarget $file.Name
        Copy-Item $file.FullName $TargetFile -Force
    }
    Write-Success "Copied root-level frontend files"
    
    # Copy subdirectories
    $SubDirs = Get-ChildItem -Path $FrontendSource -Directory
    foreach ($dir in $SubDirs) {
        $TargetSubDir = Join-Path $FrontendTarget $dir.Name
        if (Test-Path $TargetSubDir) {
            Remove-Item $TargetSubDir -Recurse -Force
        }
        Copy-Item $dir.FullName $TargetSubDir -Recurse -Force
    }
    Write-Success "Copied frontend subdirectories (assets, fonts, etc.)"
    
    # Count patched files
    $PatchedFiles = Get-ChildItem -Path $FrontendTarget -Recurse -File
    Write-Info "Total frontend files patched: $($PatchedFiles.Count)"
} else {
    Write-Status "[6/7] Skipping frontend patches..."
}

# Step 7: Repack asar
Write-Status "[7/7] Repacking asar archive..."

try {
    & npx asar pack $TempDir $AsarPath 2>&1 | Out-Null
    Write-Success "Asar repacked successfully"
} catch {
    Write-Error "Failed to repack asar: $_"
    Write-Info "Original backup is available at: $AsarPath.bak"
    exit 1
}

# Cleanup temp directory
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Success "Cleaned up temporary files"

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Patching Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Info "Original asar size: $OriginalSize"
$NewSize = Get-FileSize $AsarPath
Write-Info "Patched asar size:  $NewSize"
Write-Host ""
Write-Info "Patched file: $AsarPath"
Write-Info "Backup file:  $AsarPath.bak"
Write-Host ""
Write-Info "Please restart AnythingLLM Desktop to apply the changes."
Write-Host ""
