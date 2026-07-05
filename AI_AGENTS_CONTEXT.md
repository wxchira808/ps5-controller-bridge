# chiaki-ng custom controller-only fork context

## What this project is

This folder is a custom working copy of `streetpea/chiaki-ng`, an open-source PlayStation Remote Play client.

The user uses it in a very specific way:

- The PlayStation 5 is on the same local network as the PC.
- The stream window is not the main point of use.
- Audio and video are disabled in the app.
- The real gameplay view and audio come directly from the PS5 on a nearby monitor.
- The app is mainly being used as a low-latency controller bridge so non-native controllers can control the PS5 through Remote Play.

In short: this is not a normal "watch the stream on PC" setup. This is a "controller input relay to PS5 over local Remote Play" setup.

## Why this fork exists

The goal of this custom copy is to push chiaki-ng toward a leaner controller-only mode for local PS5 play.

The user wants to:

- use third-party controllers such as Xbox controllers on PS5 without a hardware adapter
- keep input lag as low as possible
- avoid unnecessary audio/video work when the app is only needed for controller input

## Changes already made

Initial optimization work has already been applied in this copy:

- when video is disabled, the GUI/session path skips video decoder setup
- when audio is disabled, the GUI/session path skips downstream audio decoder and sink setup
- the stream connection skips regular audio/video receiver allocation when those streams are disabled
- the haptics receiver path is kept so controller rumble can still work

Relevant files:

- `gui/include/streamsession.h`
- `gui/src/streamsession.cpp`
- `lib/src/streamconnection.c`
- `CONTROLLER_ONLY_NOTES.md`

## Important intent

Do not optimize this project as if the stream image is the primary user experience.

For this user, the priority order is:

1. controller responsiveness
2. session stability
3. controller compatibility
4. keeping enough PS5-specific features to remain usable
5. stream presentation

## Good next steps

- build and test this custom copy with `Audio and Video Disabled`
- confirm controller input still works correctly
- confirm haptics behavior still works as expected
- measure whether CPU usage or jitter is improved
- consider a dedicated controller-only launch mode later
- consider hidden/minimized auto-connect behavior later

## Constraints

- Keep the user's original packaged install separate and untouched.
- Prefer isolated changes that improve controller-only use without breaking standard local streaming.
- Avoid invasive refactors unless they are necessary for measurable latency or stability gains.

