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

# --- STEP 2.5: Check whether SARIF changed ---------------------------
$hashFile = "$outputSarif.hash"

if (Test-Path $hashFile) {
    $oldHash = Get-Content $hashFile
    $newHash = Get-RelevantSarifHash -sarifPath $outputSarif

    if ($oldHash -eq $newHash) {
        Write-Host "SARIF unchanged → skipping policy generation." -ForegroundColor Yellow
        exit 0
    }
} else {
    # Es existiert noch kein Hash, deshalb jetzt generieren
    $newHash = Get-RelevantSarifHash -sarifPath $outputSarif
}

# Hash speichern
Set-Content -Path $hashFile -Value $newHash


# --- STEP 3: GENERATE POLICY (ONLY IF SARIF CHANGED) -----------------

Write-Host "SARIF changed → Generating new DesiriGuard policy..." -ForegroundColor Cyan

py $policygen `
    --path "$outputSarif" `
    --out "$outputPolicy" `
    --jdk 8

if ($LASTEXITCODE -ne 0) {
    Write-Host "Policy generation failed!" -ForegroundColor Red
    exit 1
}

# Save hash for future comparisons
$currentHash | Out-File $hashFile

Write-Host "New policy generated." -ForegroundColor Green





function Get-RelevantSarifHash {
    param(
        [string]$sarifPath
    )

    # SARIF laden
    $json = Get-Content $sarifPath -Raw | ConvertFrom-Json

    # Metadaten entfernen, die sich jedes Mal ändern
    foreach ($run in $json.runs) {

        # 1) Versionsinfo
        if ($run.tool.driver.PSObject.Properties["semanticVersion"]) {
            $run.tool.driver.PSObject.Properties.Remove("semanticVersion")
        }

        # 2) notifications komplett entfernen (brauchen wir nicht)
        if ($run.tool.driver.PSObject.Properties["notifications"]) {
            $run.tool.driver.PSObject.Properties.Remove("notifications")
        }

        # 3) timeUtc entfernen in invocations
        foreach ($inv in $run.invocations) {
            foreach ($note in $inv.toolExecutionNotifications) {
                if ($note.PSObject.Properties["timeUtc"]) {
                    $note.PSObject.Properties.Remove("timeUtc")
                }
            }
        }
    }

    # Nur relevante Daten serialisieren
    $cleanJson = $json | ConvertTo-Json -Depth 100

    # Hash erzeugen (SHA256)
    return (New-Object System.Security.Cryptography.SHA256Managed).
            ComputeHash([System.Text.Encoding]::UTF8.GetBytes($cleanJson)) |
            ForEach-Object { $_.ToString("x2") } -join ""
}

