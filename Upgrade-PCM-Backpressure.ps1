[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$HomePodCastRepoPath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist')
)
$ErrorActionPreference = 'Stop'

$manifest = Join-Path $HomePodCastRepoPath 'Cargo.toml'
$castSource = Join-Path $HomePodCastRepoPath 'crates\homepod-cast\src\cast.rs'
$pipeTarget = Join-Path $HomePodCastRepoPath 'crates\homepod-cast\src\pipe_capture.rs'
$pipeSource = Join-Path $PSScriptRoot 'patches\pipe_capture.rs'

if (-not (Test-Path -LiteralPath $manifest)) { throw "HomePod Cast Cargo.toml not found: $manifest" }
if (-not (Test-Path -LiteralPath $castSource)) { throw "HomePod Cast cast.rs not found: $castSource" }
if (-not (Test-Path -LiteralPath $pipeTarget)) { throw "Direct PCM module not found: $pipeTarget. Apply the v0.3.0/v0.3.1 Rust patch first." }
if (-not (Select-String -LiteralPath $castSource -SimpleMatch 'pipe_capture::run_capture' -Quiet)) {
    throw 'This checkout does not appear to have the direct-PCM mode integrated in cast.rs.'
}
if (-not (Select-String -LiteralPath $pipeSource -SimpleMatch 'sender.send(LivePcmFrame' -Quiet)) {
    throw 'The bundled fixed pipe_capture.rs does not contain the blocking audio send.'
}

$backup = "$pipeTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $pipeTarget -Destination $backup -Force
Copy-Item -LiteralPath $pipeSource -Destination $pipeTarget -Force
Write-Host "Updated PCM receiver. Backup: $backup" -ForegroundColor Green

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Push-Location $HomePodCastRepoPath
try {
    Write-Host 'Building HomePod Cast only; existing go-librespot.exe is not rebuilt.' -ForegroundColor Cyan
    & cargo build -p homepod-cast --release
    if ($LASTEXITCODE -ne 0) { throw 'HomePod Cast build failed. Keep the compiler output above.' }
    $builtExe = Join-Path $HomePodCastRepoPath 'target\release\homepod-cast.exe'
    if (-not (Test-Path -LiteralPath $builtExe)) { throw "Build succeeded but executable not found: $builtExe" }
    $destination = Join-Path $OutputDirectory 'HomePod-Cast.exe'
    Copy-Item -LiteralPath $builtExe -Destination $destination -Force
    Write-Host "Built executable: $destination" -ForegroundColor Green
} finally {
    Pop-Location
}
Write-Host 'Replace only the adapter HomePod-Cast.exe after backing up the original. Keep the patched go-librespot binary.' -ForegroundColor Yellow
