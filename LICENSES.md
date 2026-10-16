# Licensing and attribution

This repository is a **patch bundle targeting more than one upstream repository**. Do not treat a single license badge or a root-level license as automatically re-licensing the patched upstream cod[...]

## Upstream components and applicable licenses

| Files / component | Upstream | License identified in upstream repository | Note |
|---|---|---|---|
| `patches/go-librespot-windows-named-pipe.patch`, `patches/go-librespot/` | [devgianlu/go-librespot](https://github.com/devgianlu/go-librespot) | GPL-3.0 | The patch modifies a Windows-specific im[...]
| `patches/homepod-cast-direct-pcm.patch`, `patches/pipe_capture.rs`, `Upgrade-PCM-Backpressure.ps1` modifications targeting the Rust app | [iakacer/windows-airplay-homepod](https://github.com/iak[...]
| `README.md` reference to design inspiration only | [herbertkokholm/homepod-spotify-connect](https://github.com/herbertkokholm/homepod-spotify-connect) | MIT | Cited as an architectural reference[...]
| `Apply-Patches.ps1`, `Build-Binaries.ps1`, `adapter-files/`, other bundle-specific docs/scripts | This patch-bundle project | No blanket license assigned here | Before choosing a license for ori[...]

## Practical recommendation

1. For GitHub, publish this as a patch/integration repository and include this `LICENSES.md`. Until the GPL-2.0 vs GPL-3.0-or-later provenance question for the Rust component has been resolved, **[...]
2. Keep the upstream license files and notices with any full source checkout or redistributed binary. Record the exact upstream commit IDs used for each release.
3. The license of each standalone upstream program remains relevant even if the two executables communicate through a local named pipe. Distribution of a combined package may introduce additional [...]
4. If you want a GitHub repo with one unambiguous license for all code, the relevant copyright holders must confirm a compatible licensing basis first. Do not choose MIT just because the reference[...]

Official license files:

- go-librespot: https://github.com/devgianlu/go-librespot/blob/master/LICENSE
- windows-airplay-homepod: https://github.com/iakacer/windows-airplay-homepod/blob/master/LICENSE
- airplay2-rs: https://github.com/lmcgartland/airplay2-rs/blob/master/LICENSE
- homepod-spotify-connect: https://github.com/herbertkokholm/homepod-spotify-connect/blob/main/LICENSE
