# Name

Media Devices Path

## Purpose

Investigate daemon-side audio/video device and media pipeline behavior.

## When To Use

- audio device issues
- video device/capture issues
- media mute or stream lifecycle issues

## When Not To Use

- purely client-side device picker layout issues

## Required First Reads

- `daemon/src/client/configurationmanager.cpp`
- `daemon/src/client/videomanager.cpp`
- `daemon/src/media/audio/`
- `daemon/src/media/video/`
- `daemon/src/media/system_codec_container.cpp`

## Navigation Heuristics

- Separate public device/configuration entry points from low-level media runtime.
- Check whether the issue is audio-only, video-only, or shared media coordination.

## Investigation Strategy

1. Identify the public device/media operation.
2. Trace into the relevant audio/video runtime owner.
3. Check cross-effects on calls or conferences.
4. Note client device-model implications if public behavior changes.

## Output Format

- media path
- owner
- neighboring impact
- validation plan

## Success Criteria

- The media/device problem is localized to the correct runtime owner.

## Risks / Pitfalls

- changing low-level media behavior without checking call/conference side effects

## Escalation Rules

- Escalate when client AV models or settings pages need coordinated updates.
