# Changelog

The current bundle version is v0.1.0. The v0.3.x entries below are historical version labels from earlier iterations.

## v0.3.0 — Direct PCM Windows backend source patch

- Implemented the Windows side of go-librespot's `pipe` audio backend via a Windows named-pipe client path.
- Made pipe connection retry behavior honor `audio_output_pipe_wait_for_reader` for missing/busy named pipes.
- Fixed the shared pipe output loop to close its file handle when an error ends the output goroutine.
- Corrected the HomePod Cast direct PCM receiver to call `LiveFrameSender::try_send` and keep the AirPlay decoder primed with silence while waiting for go-librespot.
- Added apply/build PowerShell scripts and revised instructions.
- No full upstream project build or physical HomePod test was possible in the authoring environment.

## v0.3.1 (build-script fix)

- Fix Windows MinGW linker failure `undefined reference to ogg_stream_iovecin` by forcing static linkage for libogg only via `CGO_LDFLAGS`.
- Add a clear preflight check for `libogg.a` and installation guidance when it is missing.
- Full Go/Rust builds and physical HomePod playback remain unverified in this environment.

## v0.1.0 (PCM backpressure fix)

- Replace non-blocking `LiveFrameSender::try_send` for actual audio frames with blocking `send`.
- This prevents the pipe reader from continuously draining PCM while dropping most frames; bounded-channel pressure propagates through the Windows named pipe and throttles go-librespot to the AirPlay consumer rate.
- Keep non-blocking silence keepalives while waiting for audio or handling short pipe gaps.
- Add an upgrade script that patches an already-modified HomePod Cast checkout and builds only the Rust executable (does not rebuild Go).
- This diagnosis matches the supplied symptom/log pattern, but playback timing must still be verified on the user's Windows/HomePod setup.
