/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
#include "activecallsmodel.h"

#include <QObject>
#include <QString>

// an adapter object to expose a conversation::Info struct
// as a group of observable properties
// Note: this is a view item and will always use the current accountId
class CurrentConversation final : public QObject
{
    Q_OBJECT
    QML_PROPERTY(QString, id)
    QML_PROPERTY(QString, title)
    QML_PROPERTY(QString, description)
    QML_PROPERTY(QStringList, uris)
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
    QML_PROPERTY(QStringList, errors)
    QML_PROPERTY(QStringList, backendErrors)

    // TODO: these belong in CurrentCall(which doesn't exist yet)
    QML_PROPERTY(bool, hideSelf)
    QML_PROPERTY(bool, hideAudioOnly)

public:
    explicit CurrentConversation(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CurrentConversation() = default;
    Q_INVOKABLE void scrollToMsg(const QString& msgId);
    Q_INVOKABLE void showSwarmDetails() const;
    Q_INVOKABLE void setPreference(const QString& key, const QString& value);
    Q_INVOKABLE QString getPreference(const QString& key) const;
    Q_INVOKABLE MapStringString getPreferences() const;
    Q_INVOKABLE void setInfo(const QString& key, const QString& value);

    QVector<QMap<QString, QString>> activeCalls() const;

Q_SIGNALS:
    void scrollTo(const QString& msgId);
    void showDetails() const;

private Q_SLOTS:
    void updateData();
    void onNeedsHost(const QString& convId);
    void onConversationUpdated(const QString& convId);
    void onProfileUpdated(const QString& convId);
    void updateErrors(const QString& convId);
    void updateConversationPreferences(const QString& convId);

Q_SIGNALS:
    void needsHost();

private:
    LRCInstance* lrcInstance_;
    QScopedPointer<ActiveCallsModel> activeCalls_;

    void connectModel();
};
