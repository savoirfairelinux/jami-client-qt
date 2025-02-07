/****************************************************************************
 *   Copyright (C) 2017-2025 Savoir-faire Linux Inc.                        *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#pragma once

#include "interaction.h"
#include "messagelistmodel.h"
#include "account.h"
#include "member.h"
#include "typedefs.h"

#include <memory>

namespace lrc {

namespace api {

namespace conversation {
Q_NAMESPACE
Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

enum class Mode { ONE_TO_ONE, ADMIN_INVITES_ONLY, INVITES_ONLY, PUBLIC, NON_SWARM };
Q_ENUM_NS(Mode)

static inline Mode
to_mode(const int intMode)
{
    switch (intMode) {
    case 0:
        return Mode::ONE_TO_ONE;
    case 1:
        return Mode::ADMIN_INVITES_ONLY;
    case 2:
        return Mode::INVITES_ONLY;
    case 3:
        return Mode::PUBLIC;
    case 4:
        return Mode::NON_SWARM;
    default:
        return Mode::ONE_TO_ONE;
    }
}

struct Info
{
    explicit Info(const QString& uid, const account::Info* acc)
        : uid(uid)
        , interactions(std::make_unique<MessageListModel>(acc, nullptr))
    {
        account = acc;
        if (acc) {
            accountId = acc->id;
            accountUri = acc->profileInfo.uri;
        }
    }
    Info(const Info& other) = delete;
    Info(Info&& other) = default;
    Info& operator=(const Info& other) = delete;
    Info& operator=(Info&& other) = default;

    bool allMessagesLoaded = false;
    QString uid;
    QString accountId;
    const account::Info* account {nullptr};
    QString accountUri;
    QVector<member::Member> participants;
    VectorMapStringString activeCalls;
    VectorMapStringString ignoredActiveCalls;

    QString callId;
    QString confId;
    std::unique_ptr<MessageListModel> interactions;
    QString lastSelfMessageId;
    QHash<QString, QString> parentsId; // pair messageid/parentid for messages without parent loaded
    unsigned int unreadMessages = 0;
    QVector<QPair<int, QString>> errors;

    QSet<QString> typers;

    MapStringString infos {};
    MapStringString preferences {};

    int indexOfActiveCall(const QString& confId, const QString& uri, const QString& deviceId)
    {
        for (auto idx = 0; idx != activeCalls.size(); ++idx) {
            const auto& call = activeCalls[idx];
            if (call["id"] == confId && call["uri"] == uri && call["device"] == deviceId) {
                return idx;
            }
        }
        return -1;
    }

    QString getCallId() const
    {
        return confId.isEmpty() ? callId : confId;
    }

    inline bool isLegacy() const
    {
        return mode == Mode::NON_SWARM;
    }
    inline bool isSwarm() const
    {
        return !isLegacy();
    }
    // for each contact we must have one non-swarm conversation or one active one-to-one
    // conversation. Where active means peer did not leave the conversation.
    inline bool isCoreDialog() const
    {
        return isLegacy() || mode == Mode::ONE_TO_ONE;
    };

    inline QStringList participantsUris() const
    {
        QStringList result;
        for (const auto& p : participants)
            result.append(p.uri);
        return result;
    }

    Mode mode = Mode::NON_SWARM;
    bool needsSyncing = false;
    bool isRequest = false;
};

} // namespace conversation
} // namespace api
} // namespace lrc
