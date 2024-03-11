/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
//#include "currentconversationmembers.h"

#include <QObject>
#include <QString>
#include <QApplication>

class ObservableConversation : public QObject, public UsesLibclient
{
    Q_OBJECT

    QML_PROPERTY(QString, accountId)
    QML_PROPERTY(QString, conversationId)

    QML_PROPERTY(QString, title)
    QML_PROPERTY(QString, description)
    QML_PROPERTY(bool, isSwarm)
    QML_PROPERTY(bool, isLegacy)
    QML_PROPERTY(bool, isCoreDialog)
    QML_PROPERTY(bool, isRequest)
    QML_PROPERTY(bool, needsSyncing)
    QML_PROPERTY(bool, isSip)
    QML_PROPERTY(bool, isBanned)
    QML_PROPERTY(bool, ignoreNotifications)
    QML_PROPERTY(QString, callId)
    QML_PROPERTY(QString, color)
    QML_PROPERTY(QString, rdvAccount)
    QML_PROPERTY(QString, rdvDevice)
    QML_PROPERTY(call::Status, callState)
    QML_PROPERTY(bool, inCall)
    QML_PROPERTY(bool, isTemporary)
    QML_PROPERTY(bool, isContact)
    QML_PROPERTY(bool, allMessagesLoaded)
    QML_PROPERTY(QString, modeString)
    QML_PROPERTY(QVariantList, activeCalls)
    QML_PROPERTY(QStringList, errors)
    QML_PROPERTY(QStringList, backendErrors)
    QML_PROPERTY(QString, lastSelfMessageId)
    QML_RO_PROPERTY(bool, hasCall)
    QML_RO_PROPERTY(QVariant, members)

public:
    explicit ObservableConversation(QObject* parent = nullptr);
    ~ObservableConversation() = default;

    Q_INVOKABLE void configure(const QString& accountId, const QString& convId);
    Q_SIGNAL void needsHost();

private:
    QAtomicInt initializing_;

    ConversationModel* conversationModel_;
    CallModel* callModel_;

private Q_SLOTS:
    void initialize();

    void onConversationUpdated(const QString& convId);
    void updateProfile(const QString& convId);
    void updateActiveCalls(const QString& accountId, const QString& convId);
    void updateErrors(const QString& convId);
    void updateConversationPreferences(const QString& convId);
    void onNeedsHost(const QString& convId);
    void onCallStatusChanged(const QString& callId, int);
    void onShowIncomingCallView(const QString& accountId, const QString& convId);
    void updateData();
};
