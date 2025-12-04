# ============================
# run-analysis.ps1
# ============================

Write-Host "=== Running static analysis (CodeQL + Policygen) ===" -ForegroundColor Cyan

# --- FUNCTION DEFINITIONS (MUST BE FIRST) ----------------------
function Get-RelevantSarifHash {
    param(
        [string]$sarifPath
    )

    $json = Get-Content $sarifPath -Raw | ConvertFrom-Json

    foreach ($run in $json.runs) {
        # Entferne semanticVersion überall
        Remove-JsonProperty -object $run -propertyName "semanticVersion"
        Remove-JsonProperty -object $run -propertyName "timeUtc"

    }

    $cleanJson = $json | ConvertTo-Json -Depth 100 -Compress

    $hash = (New-Object System.Security.Cryptography.SHA256Managed).
            ComputeHash([System.Text.Encoding]::UTF8.GetBytes($cleanJson)) |
            ForEach-Object { $_.ToString("x2") }

    return $hash -join ""
}

function Remove-JsonProperty {
    param(
        [object]$object,
        [string]$propertyName
    )

    if ($object.PSObject.Properties[$propertyName]) {
        $object.PSObject.Properties.Remove($propertyName)
    }

    foreach ($prop in $object.PSObject.Properties) {
        if ($prop.Value -is [System.Management.Automation.PSCustomObject] -or $prop.Value -is [array]) {
            if ($prop.Value -is [array]) {
                foreach ($item in $prop.Value) {
                    if ($item -is [System.Management.Automation.PSCustomObject]) {
                        Remove-JsonProperty -object $item -propertyName $propertyName
                    }
                }
            } else {
                Remove-JsonProperty -object $prop.Value -propertyName $propertyName
            }
        }
    }
}



# --- PATHS ---------------------------------------------------
$projectRoot = (Resolve-Path "..").Path
$scriptDir   = (Resolve-Path ".").Path

$codeql = "C:\Users\drexl\Downloads\codeql-bundle-win64.tar\codeql-bundle-win64\codeql\codeql.exe"
$policygen = "C:\Users\drexl\OneDrive\Studium\5\ITS2\Repo\DesisriGuard-2.0\policygenerator.py"

$databaseDir = Join-Path $scriptDir "java-database"
$queryResultsDir = Join-Path $scriptDir "query-results"
$outputSarif = Join-Path $queryResultsDir "query-results.sarif"
$hashFile = Join-Path $queryResultsDir "query-results.sarif.hash"
$outputPolicy = Join-Path $scriptDir "policy"

# --- CLEAN OLD DATA ------------------------------------------
if (Test-Path $databaseDir) {
    Write-Host "Deleting old database..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $databaseDir
}

if (Test-Path $outputSarif) {
    Write-Host "Deleting old SARIF..." -ForegroundColor Yellow
    Remove-Item -Force $outputSarif
}

if (Test-Path $outputPolicy) {
    Write-Host "Deleting old policy..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $outputPolicy
}

# --- CREATE QUERY RESULTS DIR --------------------------------
if (-not (Test-Path $queryResultsDir)) {
    New-Item -ItemType Directory -Path $queryResultsDir | Out-Null
}

# --- STEP 1: CREATE CODEQL DATABASE ---------------------------
Write-Host "Creating CodeQL database..." -ForegroundColor Cyan

Set-Location $projectRoot

& $codeql database create $databaseDir `
    --language=java `
    --command="mvn clean install"

if ($LASTEXITCODE -ne 0) {
    Write-Host "CodeQL database creation failed!" -ForegroundColor Red
    exit 1
}

# --- STEP 2: ANALYZE DATABASE --------------------------------
Write-Host "Analyzing with CodeQL rules..." -ForegroundColor Cyan

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
if (Test-Path $hashFile) {
    $oldHash = Get-Content $hashFile
    $newHash = Get-RelevantSarifHash -sarifPath $outputSarif

    if ($oldHash -eq $newHash) {
        Write-Host "SARIF unchanged -> skipping policy generation." -ForegroundColor Yellow
        exit 0
    }
} else {
    $newHash = Get-RelevantSarifHash -sarifPath $outputSarif
}

# --- STEP 3: GENERATE POLICY (ONLY IF SARIF CHANGED) -----------------
Write-Host "SARIF changed -> Generating new DesiriGuard policy..." -ForegroundColor Cyan

py $policygen `
    --path "$outputSarif" `
    --out "$outputPolicy" `
    --jdk 8

if ($LASTEXITCODE -ne 0) {
    Write-Host "Policy generation failed!" -ForegroundColor Red
    exit 1
}

# Save hash
Set-Content -Path $hashFile -Value $newHash

Write-Host "New policy generated." -ForegroundColor Green
