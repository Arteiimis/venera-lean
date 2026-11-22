# Windows frame-time baseline for the reader shell.
#
# Builds a profile-mode Windows runner from integration_test/performance_frames_test.dart,
# runs it directly (flutter drive cannot attach to a Windows profile build reliably),
# and collects the WIN_PERF samples the test writes to windows-frames.jsonl.
#
# Compare two runs (for example before and after a Flutter upgrade) by diffing the
# JSONL files; do not assert absolute thresholds in CI.
#
# The measured cases build generated pixels and widget trees only: the test never
# calls App.init(), so no user data, settings or network are touched. A window is
# shown while the measurement runs and is closed by this script.
#
# Usage:
#   pwsh tool/test_performance_windows.ps1 [-Fvm <path-to-fvm>] [-TimeoutSeconds 180]
param(
    [string]$Fvm = 'fvm',
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not (Get-Command $Fvm -ErrorAction SilentlyContinue)) {
    throw "fvm not found on PATH. Install fvm or pass -Fvm <path>."
}

$pinned = (Get-Content (Join-Path $root '.fvmrc') -Raw | ConvertFrom-Json).flutter
if (-not $pinned) {
    throw '.fvmrc does not pin a Flutter version.'
}
$listText = & $Fvm list 2>&1 | Out-String
if ($listText -notmatch [regex]::Escape($pinned)) {
    throw "Flutter $pinned is not installed for fvm. Run: fvm install $pinned"
}

$target = 'integration_test/performance_frames_test.dart'
if (-not (Test-Path (Join-Path $root $target))) {
    throw "Missing $target"
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $root ".dart_tool/performance-audit/win-run.$stamp"
New-Item -ItemType Directory -Force $runDir | Out-Null
$jsonlPath = Join-Path $runDir 'windows-frames.jsonl'
$buildLog = Join-Path $runDir 'build.log'

Write-Host "Flutter: $pinned"
Write-Host "Artifacts: $runDir"

# A stale sample file would merge two runs.
if (Test-Path $jsonlPath) { Remove-Item -Force $jsonlPath }

& $Fvm flutter build windows --profile --target $target `
    "--dart-define=PERF_OUT=$($jsonlPath -replace '\\', '/')" 2>&1 |
    Tee-Object -FilePath $buildLog | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --profile failed. See $buildLog"
}

$exe = Join-Path $root 'build/windows/x64/runner/Profile/venera-lean.exe'
if (-not (Test-Path $exe)) {
    throw "Missing $exe"
}

Write-Host 'Running the profile build...'
$process = Start-Process -FilePath $exe -PassThru
try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $expected = 3 # startup_to_first_frame + list_scroll + large_image_scroll
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $jsonlPath) {
            $count = @(Get-Content $jsonlPath | Where-Object { $_ -match '^WIN_PERF ' }).Count
            if ($count -ge $expected) { break }
        }
        if ($process.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
}
finally {
    if (-not $process.HasExited) {
        $process.Kill()
        $process.WaitForExit(5000) | Out-Null
    }
}

$samples = if (Test-Path $jsonlPath) {
    Get-Content $jsonlPath | Where-Object { $_ -match '^WIN_PERF (.*)$' } |
        ForEach-Object { $_.Substring(9) }
}
else { @() }

Write-Host ''
if (-not $samples -or @($samples).Count -lt 3) {
    Write-Error "Expected at least 3 samples, got $(@($samples).Count). See $runDir" -ErrorAction Continue
    exit 1
}

Write-Host "Samples: $jsonlPath"
foreach ($sample in $samples) {
    Write-Host "  $sample"
}
