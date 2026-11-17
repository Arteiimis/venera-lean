#!/usr/bin/env pwsh
# Builds the Windows installer from an existing release build.
#
# Inno Setup is not part of the Flutter toolchain: install it first
# (winget install JRSoftware.InnoSetup, or choco install innosetup) and make
# sure ISCC.exe is on PATH or passed with -Iscc.

param(
  [string]$Iscc = ''
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot

if (-not $Iscc) {
  $command = Get-Command iscc -ErrorAction SilentlyContinue
  if ($command) {
    $Iscc = $command.Source
  } else {
    $candidates = @(
      'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
      'C:\Program Files\Inno Setup 6\ISCC.exe'
    )
    $Iscc = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  }
}
if (-not $Iscc -or -not (Test-Path $Iscc)) {
  throw 'ISCC.exe was not found. Install Inno Setup 6 or pass -Iscc <path>.'
}

$releaseDir = Join-Path $repo 'build/windows/x64/runner/Release'
if (-not (Test-Path (Join-Path $releaseDir 'venera-lean.exe'))) {
  throw 'Run "flutter build windows --release" before building the installer.'
}

$version = (Select-String -Path (Join-Path $repo 'pubspec.yaml') -Pattern '^version:\s*(\S+)' -AllMatches).
  Matches[0].Groups[1].Value.Split('+')[0]

$isl = Join-Path $repo 'windows/ChineseSimplified.isl'
if (-not (Test-Path $isl)) {
  throw 'windows/ChineseSimplified.isl is missing from the checkout.'
}

$script = Get-Content (Join-Path $repo 'windows/build.iss') -Raw
$script = $script.Replace('{{version}}', $version).Replace('{{root_path}}', $repo)

# Resolve into build/ so the tracked script keeps its placeholders.
$resolved = Join-Path $repo 'build/windows/installer.iss'
New-Item -ItemType Directory -Force (Split-Path $resolved) | Out-Null
Set-Content -Path $resolved -Value $script -Encoding UTF8

New-Item -ItemType Directory -Force (Join-Path $repo 'dist') | Out-Null
& $Iscc $resolved
if ($LASTEXITCODE -ne 0) {
  throw "ISCC failed with exit code $LASTEXITCODE"
}

$installer = Join-Path $repo "dist/venera-lean-$version-windows-x64-setup.exe"
if (-not (Test-Path $installer)) {
  throw "Installer was not produced at $installer"
}
Get-Item $installer | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
