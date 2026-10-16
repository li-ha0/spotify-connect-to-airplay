# HomePod Spotify Connect for Windows — Direct PCM (Experimental)

An experimental Windows integration that aims to route Spotify Connect audio to Apple HomePod without capturing the Windows system mixer.

> **Status:** Experimental source-patch bundle. The complete Go and Rust builds and playback on a physical HomePod have not been validated end-to-end. This repository does not contain prebuilt executables or complete copies of the upstream repositories.

## GitHub repository description

Use this as the short GitHub **Description** (separate from this README):

> Experimental Windows Spotify Connect audio routing to HomePod via a direct PCM pipeline and AirPlay 2.

## Goal and architecture

```text
Spotify app
   │ Spotify Connect / Zeroconf
   ▼
go-librespot (modified Windows pipe backend)
   │ decoded PCM: signed 16-bit little-endian, stereo, 44.1 kHz
   ▼
Windows named pipe: \\.\pipe\HomePodSpotifyPcm
   ▼
HomePod Cast (modified PCM input)
   │ AirPlay 2 sender
   ▼
Apple HomePod
```

The intended benefit is to bypass WASAPI loopback/system mixing for Spotify audio. Windows master volume should therefore not govern the PCM stream sent to HomePod. This goal depends on both patched components being built and their formats and flow control remaining compatible.

## What this repository contains

- `patches/go-librespot-windows-named-pipe.patch` and `patches/go-librespot/`: the Windows named-pipe output changes for go-librespot.
- `patches/homepod-cast-direct-pcm.patch` and `patches/pipe_capture.rs`: the HomePod Cast PCM receiver changes.
- `Apply-Patches.ps1`: checks and applies the source patches.
- `Build-Binaries.ps1`: builds the Go and Rust executables.
- `Upgrade-PCM-Backpressure.ps1`: updates the PCM receiver in an already-patched checkout to apply backpressure and reduce fast track progression.
- `adapter-files/`: related Windows control-panel scripts.

This repository is a patch bundle, not a replacement for the upstream source repositories. The build scripts clone neither repository automatically; clone them as shown below.

## Upstream projects

- [devgianlu/go-librespot](https://github.com/devgianlu/go-librespot) — Spotify Connect-compatible client written in Go; upstream license: GPL-3.0.
- [iakacer/windows-airplay-homepod](https://github.com/iakacer/windows-airplay-homepod) — Windows HomePod Cast / AirPlay sender; its repository currently contains a GPL-2.0 license file.
- [herbertkokholm/homepod-spotify-connect](https://github.com/herbertkokholm/homepod-spotify-connect) — architectural reference for routing Spotify audio to HomePod; upstream license: MIT. It is listed as a reference, not as a runtime dependency of this patch bundle.
- [lmcgartland/airplay2-rs](https://github.com/lmcgartland/airplay2-rs) — related AirPlay 2 Rust implementation. Its current repository declares GPL-3.0-or-later; check the exact source revision and notices for the code you use.

## Requirements

- 64-bit Windows 10/11
- Git
- Go 1.25+ (the upstream Go revision used for development may require this)
- Rust stable and Cargo
- MinGW-w64 / MSYS2 MINGW64 with GCC, `dlltool`, `pkg-config`, and the required audio codec development packages for the Go build
- An Apple HomePod and Windows PC reachable on the same LAN

For MSYS2 MINGW64, the codec packages used by the Go project include:

```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-pkg-config \
  mingw-w64-x86_64-libogg mingw-w64-x86_64-libvorbis \
  mingw-w64-x86_64-flac mingw-w64-x86_64-mpg123
```

Ensure `C:\msys64\mingw64\bin` is on `PATH`, or pass your actual MinGW `bin` directory to the build script.

## Build from source

Open PowerShell in the extracted project directory (the directory containing `Apply-Patches.ps1`). Clone the upstream repositories into subdirectories. Do this only once in each working directory:

```powershell
git clone https://github.com/devgianlu/go-librespot.git .\go-librespot
git clone https://github.com/iakacer/windows-airplay-homepod.git .\windows-airplay-homepod
```

Apply the patches:

```powershell
.\Apply-Patches.ps1
```

If a patch check fails, stop; do not force-apply it to a different source revision. Upstream `master` can change, so record the output of `git -C .\go-librespot rev-parse HEAD` and `git -C .\windows-airplay-homepod rev-parse HEAD` in your release notes when publishing a tested build.

Build both binaries:

```powershell
rustup default stable-x86_64-pc-windows-gnu
.\Build-Binaries.ps1 -MingwBin 'C:\msys64\mingw64\bin'
```

Expected output files, if both builds succeed:

```text
dist\go-librespot.exe
dist\HomePod-Cast.exe
```

Do not distribute or replace existing executables unless both builds succeed. A successful compile alone does not prove live HomePod playback works.

### Common build issue: `ogg_stream_iovecin`

If Go linking reports `undefined reference to ogg_stream_iovecin`, check that `C:\msys64\mingw64\lib\libogg.a` exists and that the correct MINGW64 toolchain is being used. The supplied Go build script attempts to link `libogg` statically for this case. This workaround is specific to that linker error and is not a general fix for Rust linking errors.

### Rust GNU linker issue

If the Rust linker reports many `.drectve` / `-exclude-symbols` warnings followed by `ld returned 5`, preserve the complete `cargo build -vv` output. The top-level warning summaries are not the actual linker diagnosis. Do not assume the executable was built unless the exit code is `0` and the output file exists.

## Install and run

After both builds succeed, stop the old HomePod Cast and go-librespot processes and back up their existing executables. Copy the newly built binaries into the Windows adapter's `bin` directory:

```powershell
$adapter = "$env:USERPROFILE\Downloads\homepod-spotify-connect-windows-v0.2.1\homepod-spotify-connect-windows"
Copy-Item '.\dist\go-librespot.exe' (Join-Path $adapter 'bin\go-librespot.exe') -Force
Copy-Item '.\dist\HomePod-Cast.exe' (Join-Path $adapter 'bin\HomePod-Cast.exe') -Force
```

Change `$adapter` to your actual adapter folder. Keep a backup of the original EXEs. Use the modified `HomePodSpotifyConnect.ps1` and `Install.ps1` from `adapter-files`; do not let the original installer replace the patched go-librespot binary with an upstream release binary.

The go-librespot config for direct PCM should include:

```yaml
audio_backend: pipe
audio_output_pipe: '\\.\pipe\HomePodSpotifyPcm'
audio_output_pipe_format: s16le
audio_output_pipe_wait_for_reader: true
```

Start the patched HomePod Cast first, choose the HomePod in its tray menu, and wait for the AirPlay session. Then start Spotify Connect from the modified control panel and play a track. Test whether playback continues when the Windows master volume is muted and whether the PC speakers stay silent.

## Troubleshooting

- `pipe output is not supported on Windows`: the patched Go source was not applied or you launched an unpatched executable.
- `bind: Only one usage of each socket address...3678`: another go-librespot process is already using its API port. Find the owner before stopping anything.
- `failed to open Windows named pipe`: verify the receiver is started first, the path matches exactly, and the patched binaries are the ones running.
- Tracks advance too quickly: keep both process logs. The PCM receiver must apply backpressure; simply draining pipe bytes faster than AirPlay consumes them can cause playback timing problems.
- HomePod is silent: save Go and Rust logs and verify both builds use the same PCM format.

## Licensing and attribution

This repository contains patches targeting separately licensed upstream projects. **There is no single blanket license applied to every file in this bundle.** See [`LICENSES.md`](LICENSES.md) before redistributing patches or binaries. In particular, the current `windows-airplay-homepod` repository declares GPL-2.0 while the related `airplay2-rs` repository currently declares GPL-3.0-or-later; verify the provenance and exact revisions of inherited source before redistributing a combined derivative. This README is informational and not legal advice.

## Disclaimer

This is an independent experimental project and is not affiliated with or endorsed by Spotify or Apple. Spotify and HomePod are trademarks of their respective owners.
