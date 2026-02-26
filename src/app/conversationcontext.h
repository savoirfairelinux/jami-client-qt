/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
#include "currentconversationmembers.h"

#include <QObject>
#include <QString>
#include <QQmlEngine>
#include <QApplication>

class FilteredMsgListModel;

// An adapter object to expose a conversation::Info struct
// as a group of observable properties, locked to a specific convId + accountId.
// Unlike CurrentConversation, this does NOT track the global selectedConvUid.
class ConversationContext final : public QObject
{
    Q_OBJECT

    QML_PROPERTY(QString, id)
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
    QML_PROPERTY(QVariant, messageListModel)

    Q_PROPERTY(QString convId READ getConvId CONSTANT)
    Q_PROPERTY(QString accountId READ getAccountId CONSTANT)

public:
    explicit ConversationContext(LRCInstance* lrcInstance,
                                 const QString& convId,
                                 const QString& accountId,
                                 QObject* parent = nullptr);
    ~ConversationContext() = default;

    QString getConvId() const { return convId_; }
    QString getAccountId() const { return accountId_; }

    Q_INVOKABLE void scrollToMsg(const QString& msgId);
    Q_INVOKABLE void setPreference(const QString& key, const QString& value);
    Q_INVOKABLE QString getPreference(const QString& key) const;
    Q_INVOKABLE MapStringString getPreferences() const;
    Q_INVOKABLE void setInfo(const QString& key, const QString& value);
    Q_INVOKABLE void loadMoreMessages();

Q_SIGNALS:
    void reloadInteractions();
    void scrollTo(const QString& msgId);
    void showSwarmDetails();
    void newInteraction();
    void moreMessagesLoaded(int loadingRequestId);
    void fileCopied(const QString& dest);

private Q_SLOTS:
    void updateData();
    void onNeedsHost(const QString& convId);
    void onConversationUpdated(const QString& convId);
    void updateProfile(const QString& convId);
    void updateErrors(const QString& convId);
    void updateConversationPreferences(const QString& convId);
    void updateActiveCalls(const QString&, const QString& convId);
    void onCallStatusChanged(const QString& accountId, const QString& callId, int code);
    void onShowIncomingCallView(const QString& accountId, const QString& convUid);

Q_SIGNALS:
    void needsHost();

private:
    LRCInstance* lrcInstance_;
    CurrentConversationMembers* membersModel_;
    FilteredMsgListModel* filteredMsgListModel_;
    QString convId_;
    QString accountId_;

    void connectModel();
};
