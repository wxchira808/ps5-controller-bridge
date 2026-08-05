Controller-only optimization notes

What this custom checkout changes

- Keeps your original `chiaki-ng-Win` install untouched.
- Works inside the source checkout at `chiaki-ng-custom`.
- Reuses the existing `Audio/Video Disabled` setting instead of inventing a new mode.
- Skips video decoder setup when video is disabled.
- Skips downstream audio decoder and sink setup when audio is disabled.
- Skips regular audio/video receiver allocation in the stream connection when those streams are disabled.
- Normal builds keep haptics receiver setup intact when haptics audio is enabled.

Dedicated Windows bridge mode

- The GitHub Actions Windows build enables `CHIAKI_CONTROLLER_ONLY_BRIDGE`.
- It forces audio, video, microphone, and haptics-audio off even if an older saved setting says otherwise.
- It keeps controller input, keyboard/mouse controller mapping, touchpad mapping, normal rumble messages, adaptive-trigger messages, and session heartbeats.
- It drops unwanted media packets before AV parsing or decryption and does not allocate their receivers or codecs.
- It polls SDL controller events every 1 ms with a precise timer and raises the Windows feedback-sender thread to high, non-realtime priority.

Why this is useful

- The protocol layer already drops disabled AV packets, but the GUI/session layer was still creating more AV machinery than a controller-only session needs.
- This reduces background work for the exact setup where the app is only being used as an input bridge.

Files changed

- `gui/include/streamsession.h`
- `gui/src/streamsession.cpp`
- `lib/src/streamconnection.c`

What is not done yet

- There is no runtime `controller-only` UI toggle; the dedicated Windows artifact is controller-only at build time.
- The app still opens the normal stream window.
- Runtime behavior still needs to be tested against a PS5 after the Windows artifact builds.

Best next step

- Build this checkout and verify that the dedicated bridge artifact connects cleanly and still sends controller and keyboard/mouse-mapped input.
- If that goes well, the next improvement would be a true hidden/minimized auto-connect launch path so the app behaves more like a background controller bridge.
