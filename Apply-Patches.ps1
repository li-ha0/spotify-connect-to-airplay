[CmdletBinding()]
param(
    [string]$GoRepoPath = (Join-Path $PSScriptRoot 'go-librespot'),
    [string]$HomePodCastRepoPath = (Join-Path $PSScriptRoot 'windows-airplay-homepod')
)
$ErrorActionPreference = 'Stop'

function Test-GitPatch([string]$RepoPath, [string]$PatchPath, [string]$Label) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoPath '.git'))) {
        throw "$Label repository not found at: $RepoPath. Clone the upstream repository first."
    }
    Write-Host "Checking $Label patch..." -ForegroundColor Cyan
    & git -C $RepoPath apply --check $PatchPath
    if ($LASTEXITCODE -ne 0) {
        throw "$Label patch does not apply cleanly. No patch was applied. Check the repository revision and local changes."
    }
}

$goPatch = Join-Path $PSScriptRoot 'patches\go-librespot-windows-named-pipe.patch'
$castPatch = Join-Path $PSScriptRoot 'patches\homepod-cast-direct-pcm.patch'
Test-GitPatch $GoRepoPath $goPatch 'go-librespot Windows named-pipe'
Test-GitPatch $HomePodCastRepoPath $castPatch 'HomePod Cast direct PCM'

& git -C $GoRepoPath apply $goPatch
if ($LASTEXITCODE -ne 0) { throw 'Failed applying go-librespot patch.' }
& git -C $HomePodCastRepoPath apply $castPatch
if ($LASTEXITCODE -ne 0) { throw 'Failed applying HomePod Cast patch.' }
Write-Host 'Both patches applied. Build both projects before using audio_backend: pipe.' -ForegroundColor Green
