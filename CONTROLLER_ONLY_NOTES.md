Controller-only optimization notes

What this custom checkout changes

- Keeps your original `chiaki-ng-Win` install untouched.
- Works inside the source checkout at `chiaki-ng-custom`.
- Reuses the existing `Audio/Video Disabled` setting instead of inventing a new mode.
- Skips video decoder setup when video is disabled.
- Skips downstream audio decoder and sink setup when audio is disabled.
- Skips regular audio/video receiver allocation in the stream connection when those streams are disabled.
- Keeps haptics receiver setup intact so controller rumble support still has a path.

Why this is useful

- The protocol layer already drops disabled AV packets, but the GUI/session layer was still creating more AV machinery than a controller-only session needs.
- This reduces background work for the exact setup where the app is only being used as an input bridge.

Files changed

- `gui/include/streamsession.h`
- `gui/src/streamsession.cpp`
- `lib/src/streamconnection.c`

What is not done yet

- There is no dedicated `controller-only` UI toggle yet.
- The app still opens the normal stream window.
- This pass has not been compiled or runtime-tested in this environment.

Best next step

- Build this checkout and verify that a session with `Audio and Video Disabled` still connects cleanly, still sends controller input, and still keeps haptics working where expected.
- If that goes well, the next improvement would be a true hidden/minimized auto-connect launch path so the app behaves more like a background controller bridge.
