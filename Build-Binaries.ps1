[CmdletBinding()]
param(
    [string]$GoRepoPath = (Join-Path $PSScriptRoot 'go-librespot'),
    [string]$HomePodCastRepoPath = (Join-Path $PSScriptRoot 'windows-airplay-homepod'),
    [string]$MingwBin = 'C:\msys64\mingw64\bin'
)
$ErrorActionPreference = 'Stop'
$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $GoRepoPath 'go.mod'))) { throw "go-librespot source not found: $GoRepoPath" }
if (-not (Test-Path -LiteralPath (Join-Path $HomePodCastRepoPath 'Cargo.toml'))) { throw "HomePod Cast source not found: $HomePodCastRepoPath" }
if (Test-Path -LiteralPath $MingwBin) {
    $env:PATH = "$MingwBin;$env:PATH"
    $mingwRoot = Split-Path -Parent $MingwBin
    $pkg = Join-Path $mingwRoot 'lib\pkgconfig'
    if (Test-Path -LiteralPath $pkg) { $env:PKG_CONFIG_PATH = $pkg }
}

$goVersion = (& go env GOVERSION 2>$null) -replace '^go',''
if (-not $goVersion) { throw 'Go is not installed or not available on PATH.' }
try { $parsedGo = [version]($goVersion -replace '[^0-9.].*$','') } catch { throw "Could not parse Go version: $goVersion" }
if ($parsedGo -lt [version]'1.25') { throw "Current upstream go-librespot requires Go 1.25 or newer; found $goVersion. Install a current Go toolchain first." }

Push-Location $GoRepoPath
$previousCgoLdFlags = $env:CGO_LDFLAGS
try {
    # MSYS2's shared libogg import library may not export ogg_stream_iovecin,
    # while libogg.a does. Force-link libogg statically only, leaving the
    # remaining codec libraries with their default linkage.
    $mingwLib = Join-Path (Split-Path -Parent $MingwBin) 'lib'
    $oggStaticLib = Join-Path $mingwLib 'libogg.a'
    if (-not (Test-Path -LiteralPath $oggStaticLib)) {
        throw "Static libogg was not found at '$oggStaticLib'. In the MSYS2 MINGW64 shell run: pacman -S mingw-w64-x86_64-libogg, then retry."
    }

    $staticOggFlags = '-Wl,-Bstatic -logg -Wl,-Bdynamic'
    if ([string]::IsNullOrWhiteSpace($previousCgoLdFlags)) {
        $env:CGO_LDFLAGS = $staticOggFlags
    } else {
        $env:CGO_LDFLAGS = "$previousCgoLdFlags $staticOggFlags"
    }

    Write-Host "Building patched go-librespot with $goVersion..." -ForegroundColor Cyan
    Write-Host 'Using static libogg to resolve the missing ogg_stream_iovecin export.' -ForegroundColor DarkCyan
    & go build -v -o (Join-Path $dist 'go-librespot.exe') .\cmd\daemon
    if ($LASTEXITCODE -ne 0) { throw 'go-librespot build failed. See the first compiler/linker error above.' }
} finally {
    if ($null -eq $previousCgoLdFlags) {
        Remove-Item Env:CGO_LDFLAGS -ErrorAction SilentlyContinue
    } else {
        $env:CGO_LDFLAGS = $previousCgoLdFlags
    }
    Pop-Location
}

Push-Location $HomePodCastRepoPath
try {
    Write-Host 'Building patched HomePod Cast...' -ForegroundColor Cyan
    & cargo build -p homepod-cast --release
    if ($LASTEXITCODE -ne 0) { throw 'HomePod Cast build failed. See compiler output above.' }
    $castExe = Join-Path $HomePodCastRepoPath 'target\release\homepod-cast.exe'
    if (-not (Test-Path -LiteralPath $castExe)) { throw "Cargo succeeded but executable was not found: $castExe" }
    Copy-Item -LiteralPath $castExe -Destination (Join-Path $dist 'HomePod-Cast.exe') -Force
} finally { Pop-Location }

Write-Host ''
Write-Host 'Builds completed. Output files:' -ForegroundColor Green
Get-ChildItem -LiteralPath $dist -File | Select-Object Name,Length,LastWriteTime
Write-Host 'These binaries still require end-to-end testing with your HomePod before being treated as production-ready.' -ForegroundColor Yellow
