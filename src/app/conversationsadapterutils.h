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

#include "api/call.h"

namespace ConversationsAdapterUtils {

struct CallDisplayInfo
{
    bool callStackViewShouldShow {false};
    lrc::api::call::Status callState {};
};

inline CallDisplayInfo
getCallDisplayInfo(const lrc::api::call::Info* call)
{
    if (!call)
        return {};

    using lrc::api::call::Status;
    const auto status = call->status;
    const auto incomingCallShouldShow = !call->isOutgoing
                                        && (status == Status::IN_PROGRESS || status == Status::PAUSED
                                            || status == Status::INCOMING_RINGING);
    const auto outgoingCallShouldShow = call->isOutgoing && status != Status::ENDED;

    return {incomingCallShouldShow || outgoingCallShouldShow, status};
}

} // namespace ConversationsAdapterUtils
