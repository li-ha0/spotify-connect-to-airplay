# Licensing and attribution

This repository is a **patch bundle targeting more than one upstream repository**. Do not treat a single license badge or a root-level license as automatically re-licensing the patched upstream code.

## Upstream components and applicable licenses

| Files / component | Upstream | License identified in upstream repository | Note |
|---|---|---|---|
| `patches/go-librespot-windows-named-pipe.patch`, `patches/go-librespot/` | [devgianlu/go-librespot](https://github.com/devgianlu/go-librespot) | GPL-3.0 | The patch modifies a Windows-specific implementation point in go-librespot. Preserve upstream copyright/license notices and comply with GPL-3.0 when distributing modified source or binaries. |
| `patches/homepod-cast-direct-pcm.patch`, `patches/pipe_capture.rs`, `Upgrade-PCM-Backpressure.ps1` modifications targeting the Rust app | [iakacer/windows-airplay-homepod](https://github.com/iakacer/windows-airplay-homepod) | Repository LICENSE/Cargo metadata identify GPL-2.0 | The related [lmcgartland/airplay2-rs](https://github.com/lmcgartland/airplay2-rs) repository currently declares GPL-3.0-or-later, while the Windows fork declares GPL-2.0. This is a licensing-provenance discrepancy to resolve with the relevant copyright holder before redistributing inherited/combined derived code. Do not assume GPL-2.0 and GPL-3.0 are interchangeable. |
| `README.md` reference to design inspiration only | [herbertkokholm/homepod-spotify-connect](https://github.com/herbertkokholm/homepod-spotify-connect) | MIT | Cited as an architectural reference. The MIT license applies to its own code, not automatically to this repository. |
| `Apply-Patches.ps1`, `Build-Binaries.ps1`, `adapter-files/`, other bundle-specific docs/scripts | This patch-bundle project | No blanket license assigned here | Before choosing a license for original files, confirm which files are wholly original and whether any code was copied/adapted from upstream. |

## Practical recommendation

1. For GitHub, publish this as a patch/integration repository and include this `LICENSES.md`. Until the GPL-2.0 vs GPL-3.0-or-later provenance question for the Rust component has been resolved, **do not select one root-level license that purports to cover every file**.
2. Keep the upstream license files and notices with any full source checkout or redistributed binary. Record the exact upstream commit IDs used for each release.
3. The license of each standalone upstream program remains relevant even if the two executables communicate through a local named pipe. Distribution of a combined package may introduce additional obligations; review the applicable license texts and seek legal advice if needed.
4. If you want a GitHub repo with one unambiguous license for all code, the relevant copyright holders must confirm a compatible licensing basis first. Do not choose MIT just because the reference project uses MIT.

Official license files:

- go-librespot: https://github.com/devgianlu/go-librespot/blob/master/LICENSE
- windows-airplay-homepod: https://github.com/iakacer/windows-airplay-homepod/blob/master/LICENSE
- airplay2-rs: https://github.com/lmcgartland/airplay2-rs/blob/master/LICENSE
- homepod-spotify-connect: https://github.com/herbertkokholm/homepod-spotify-connect/blob/main/LICENSE
