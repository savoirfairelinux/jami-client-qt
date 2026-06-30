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

#include "callcontroldevice.h"

#include <gtest/gtest.h>

// Off-hook while a call is already active must be a no-op. Driving the off-hook
// LED on connect makes devices like the Poly Sync 60-M echo an off-hook report;
// if that were treated as "hang up" the call would drop right after connecting.
TEST(CallControlDevice, OffHookWhileInCallDoesNotHangUp)
{
    EXPECT_EQ(hookSwitchAction(/*offHook*/ true, /*ringing*/ false, /*inCall*/ true),
              HookSwitchAction::None);
}

// Off-hook while ringing answers the incoming call.
TEST(CallControlDevice, OffHookWhileRingingAnswers)
{
    EXPECT_EQ(hookSwitchAction(/*offHook*/ true, /*ringing*/ true, /*inCall*/ false),
              HookSwitchAction::Accept);
}

// On-hook during an active call hangs it up.
TEST(CallControlDevice, OnHookWhileInCallHangsUp)
{
    EXPECT_EQ(hookSwitchAction(/*offHook*/ false, /*ringing*/ false, /*inCall*/ true),
              HookSwitchAction::HangUp);
}

// Hook changes with no call are ignored.
TEST(CallControlDevice, NoCallIsNoOp)
{
    EXPECT_EQ(hookSwitchAction(true, false, false), HookSwitchAction::None);
    EXPECT_EQ(hookSwitchAction(false, false, false), HookSwitchAction::None);
}
