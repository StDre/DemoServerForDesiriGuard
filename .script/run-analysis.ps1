# ============================
# run-analysis.ps1
# ============================

Write-Host "=== Running static analysis (CodeQL + Policygen) ===" -ForegroundColor Cyan

# --- PATHS ---------------------------------------------------
$projectRoot = (Resolve-Path "..").Path
$scriptDir   = (Resolve-Path ".").Path

$codeql = "C:\Users\drexl\Downloads\codeql-bundle-win64.tar\codeql-bundle-win64\codeql\codeql.exe"
$policygen = "C:\Users\drexl\OneDrive\Studium\5\ITS2\Repo\DesisriGuard-2.0\policygenerator.py"

$databaseDir = Join-Path $scriptDir "java-database"
$outputSarif = Join-Path $scriptDir "query-results.sarif"
$outputPolicy = Join-Path $scriptDir "policy"

# --- CLEAN OLD DATA ------------------------------------------
if (Test-Path $databaseDir) {
    Write-Host "Deleting old database..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $databaseDir
}

if (Test-Path $outputSarif) {
    Remove-Item $outputSarif
}

if (Test-Path $outputPolicy) {
    Remove-Item $outputPolicy
}

# --- STEP 1: CREATE CODEQL DATABASE ---------------------------
Write-Host " Creating CodeQL database..." -ForegroundColor Cyan

Set-Location $projectRoot

& $codeql database create $databaseDir `
    --language=java `
    --command="mvn clean install"

if ($LASTEXITCODE -ne 0) {
    Write-Host " CodeQL database creation failed!" -ForegroundColor Red
    exit 1
}

# --- STEP 2: ANALYZE DATABASE --------------------------------
Write-Host " Analyzing with CodeQL rules..." -ForegroundColor Cyan

Set-Location $scriptDir

& $codeql database analyze $databaseDir `
    ".\desiriguard-queries" `
    --format=sarifv2.1.0 `
    --output=$outputSarif

if ($LASTEXITCODE -ne 0) {
    Write-Host "CodeQL analysis failed!" -ForegroundColor Red
    exit 1
}

# --- STEP 3: GENERATE POLICY ---------------------------------
Write-Host "Generating DesiriGuard policy..." -ForegroundColor Cyan

# Python Script ausführen
py $policygen `
    --path "$outputSarif" `
    --out "$outputPolicy" `
    --jdk 8

if ($LASTEXITCODE -ne 0) {
    Write-Host "Policy generation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Analysis complete. Policy stored as $outputPolicy" -ForegroundColor Green
