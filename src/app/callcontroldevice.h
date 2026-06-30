/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include <QObject>

#include <memory>

// Bridges USB HID Telephony "call control" devices (speakerphones, headsets such
// as the Poly Sync 60-M) to the application. It reports the hook-switch and mute
// hardware buttons as signals, and reflects the current call state back to the
// device LEDs (incoming ring, active call, microphone mute).
//
// The actual device access is platform specific and lives behind a pimpl: the
// Linux implementation talks to hidraw via libudev, while other platforms use a
// no-op stub for now.
class CallControlDevice : public QObject
{
    Q_OBJECT

public:
    explicit CallControlDevice(QObject* parent = nullptr);
    ~CallControlDevice();

    // Reflect the current call state onto the device LEDs. Safe to call on any
    // platform; the stub implementation ignores them.
    void setRinging(bool ringing);
    void setInCall(bool inCall);
    void setMuted(bool muted);

    // True when at least one call-control device is currently connected. Lets
    // callers skip per-call bookkeeping on the common no-device path.
    bool hasDevice() const;

Q_SIGNALS:
    // The hook-switch state changed. The HID Telephony hook switch is an absolute
    // on/off control (offHook == true means "be in a call", false means "hang
    // up"), not a momentary press, so the new state is reported and the
    // application maps it to an action with hookSwitchAction().
    void hookSwitchChanged(bool offHook);
    // The user pressed the mute button.
    void muteToggleRequested();
    // A call-control device became available (e.g. hot-plugged), so the current
    // call state should be re-applied to it.
    void deviceConnected();

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;
};

// Action to take for a hook-switch state change, given the current call state.
enum class HookSwitchAction { None, Accept, HangUp };

// Map an absolute hook-switch state to a call action. The hook switch reports
// off-hook ("be in a call") or on-hook ("hang up") rather than a momentary
// press, so:
//   - off-hook only answers a ringing call; if a call is already active it is a
//     no-op. This is essential because driving the off-hook LED makes some
//     devices (e.g. the Poly Sync 60-M) echo an off-hook report, and treating
//     that echo as "hang up" would drop the call we just connected.
//   - on-hook hangs up an active call.
inline HookSwitchAction
hookSwitchAction(bool offHook, bool ringing, bool inCall)
{
    if (offHook)
        return ringing ? HookSwitchAction::Accept : HookSwitchAction::None;
    return inCall ? HookSwitchAction::HangUp : HookSwitchAction::None;
}
