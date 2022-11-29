/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon   <nicolas.vengeon@savoirfairelinux.com>
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

#include "lrcinstance.h"
#include "qmladapterbase.h"
#include "positioning.h"
#include "positionobject.h"
#include "systemtray.h"

#include <QObject>
#include <QString>

class PositionManager : public QmlAdapterBase
{
    Q_OBJECT
    QML_RO_PROPERTY(bool, isMapActive)
    QML_RO_PROPERTY(int, timeSharingRemaining)
    QML_PROPERTY(int, positionShareConvIdsCount)
    QML_PROPERTY(int, sharingUrisCount)
    QML_PROPERTY(bool, mapAutoOpening)
public:
    explicit PositionManager(SystemTray* systemTray,
                             LRCInstance* instance,
                             QObject* parent = nullptr);
    ~PositionManager() = default;

Q_SIGNALS:
    void positioningError(const QString error);
    void positionShareAdded(const QVariantMap& shareInfo);
    void positionShareUpdated(const QVariantMap& posInfo);
    void positionShareRemoved(const QString& uri);

protected:
    void safeInit() override;

    QString getAvatar(const QString& accountId, const QString& peerId);
    QVariantMap parseJsonPosition(const QString& body, const QString& peerId);
    void positionWatchDog();
    void startPositionTimers(int timeSharing);
    void stopPositionTimers();

    Q_INVOKABLE void connectAccountModel();
    Q_INVOKABLE void setMapActive(bool state);
    Q_INVOKABLE void sharePosition(int maximumTime);
    Q_INVOKABLE void stopSharingPosition(const QString convId = "");

    Q_INVOKABLE void startPositioning();
    Q_INVOKABLE void stopPositioning();

    Q_INVOKABLE QString getSelectedConvId();
    Q_INVOKABLE bool isPositionSharedToConv(const QString& convUri);
    Q_INVOKABLE bool isConvSharingPosition(const QString& convUri);

    Q_INVOKABLE void loadPreviousLocations();

private Q_SLOTS:
    void onPositionErrorReceived(const QString error);
    void onPositionReceived(const QString& accountId,
                            const QString& peerId,
                            const QString& body,
                            const uint64_t& timestamp,
                            const QString& daemonId);
    void sendPosition(const QString& body);
    void onWatchdogTimeout();
    void showNotification(const QString& accountId, const QString& convId, const QString& from);

private:
    SystemTray* systemTray_;
    std::unique_ptr<Positioning> localPositioning_;
    QTimer* timerTimeLeftSharing_ = nullptr;
    QTimer* timerStopSharing_ = nullptr;
    QSet<QPair<QString, QString>> currentConvSharingUris_;
    QMap<QPair<QString, QString>, PositionObject*> objectListSharingUris_;
    QList<QPair<QString, QString>> positionShareConvIds_;
};
