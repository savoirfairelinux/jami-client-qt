/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "lrcinstance.h"

#include <QObject>
#include <QString>

// an adapter object to expose a conversation::Info struct
// as a group of observable properties
// Note: this is a view item and will always use the current accountId
class CurrentConversation final : public QObject
{
    Q_OBJECT
    QML_RO_PROPERTY(QString, id)
    QML_RO_PROPERTY(QString, title)
    QML_RO_PROPERTY(QStringList, uris)
    QML_RO_PROPERTY(bool, isSwarm)
    QML_RO_PROPERTY(bool, isLegacy)
    QML_RO_PROPERTY(bool, isCoreDialog)
    QML_RO_PROPERTY(bool, isRequest)
    QML_RO_PROPERTY(bool, readOnly)
    QML_RO_PROPERTY(bool, needsSyncing)
    QML_RO_PROPERTY(bool, isSip)
    QML_RO_PROPERTY(QString, callId)
    QML_RO_PROPERTY(call::Status, callState)
    QML_RO_PROPERTY(bool, inCall)
    QML_RO_PROPERTY(bool, isTemporary)
    QML_RO_PROPERTY(bool, isContact)

public:
    explicit CurrentConversation(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CurrentConversation() = default;

private Q_SLOTS:
    void updateData();
    void onConversationUpdated(const QString& convId);

private:
    LRCInstance* lrcInstance_;

    void connectModel();
};
