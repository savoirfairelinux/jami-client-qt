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

// No-op CallControlDevice implementation for platforms without HID Telephony
// support yet (Windows, macOS). Button signals are never emitted and LED state
// updates are ignored.

#include "callcontroldevice.h"

class CallControlDevice::Impl
{};

CallControlDevice::CallControlDevice(QObject* parent)
    : QObject(parent)
{}

CallControlDevice::~CallControlDevice() = default;

void
CallControlDevice::setRinging(bool)
{}

void
CallControlDevice::setInCall(bool)
{}

void
CallControlDevice::setMuted(bool)
{}
