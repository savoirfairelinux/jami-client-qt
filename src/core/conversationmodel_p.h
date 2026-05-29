/*
 * Copyright (C) 2017-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include "api/conversationmodel.h"
#include "api/behaviorcontroller.h"
#include "api/datatransfer.h"
#include "containerview.h"
#include "typedefs.h"

#include <map>

namespace lrc {

class CallbacksHandler;
class Database;

using namespace api;

/**
 * Private data for ConversationModel. Pure data struct (no methods, not a QObject).
 * Follows the Qt d-pointer pattern.
 */
struct ConversationModelPrivate
{
    ConversationModelPrivate(Lrc& lrc,
                             Database& db,
                             const CallbacksHandler& callbacksHandler,
                             const BehaviorController& behaviorController)
        : lrc(lrc)
        , db(db)
        , callbacksHandler(callbacksHandler)
        , behaviorController(behaviorController)
        , typeFilter(FilterType::INVALID)
        , customTypeFilter(FilterType::INVALID)
        , mediaResearchRequestId(0)
        , msgResearchRequestId(0)
    {}

    Lrc& lrc;
    Database& db;
    const CallbacksHandler& callbacksHandler;
    const BehaviorController& behaviorController;

    ConversationModel::ConversationQueue conversations;
    ConversationModel::ConversationQueue searchResults;

    ConversationModel::ConversationQueueProxy filteredConversations;
    ConversationModel::ConversationQueueProxy customFilteredConversations;

    std::map<QString, int> conversationMap;

    QString currentFilter;
    FilterType typeFilter;
    FilterType customTypeFilter;

    MapStringString transfIdToDbIntId;
    uint32_t mediaResearchRequestId;
    uint32_t msgResearchRequestId;
};

} // namespace lrc
