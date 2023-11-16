/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

#include <QMutex>
#include <QObject>
#include <QString>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class PositionManager : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

    // map of elements : map key and isUnpin
    QML_PROPERTY(QVariantMap, mapStatus)
    QML_PROPERTY(bool, mapAutoOpening)
    QML_PROPERTY(int, positionShareConvIdsCount)
    QML_PROPERTY(int, sharingUrisCount)
public:
    static PositionManager* create(QQmlEngine*, QJSEngine*)
    {
        return new PositionManager(qApp->property("AppSettingsManager").value<AppSettingsManager*>(),
                                   qApp->property("SystemTray").value<SystemTray*>(),
                                   qApp->property("LRCInstance").value<LRCInstance*>());
    }

    explicit PositionManager(AppSettingsManager* settingsManager,
                             SystemTray* systemTray,
                             LRCInstance* instance,
                             QObject* parent = nullptr);
    ~PositionManager() = default;

Q_SIGNALS:
    void positioningError(const QString error);
    void positionShareAdded(const QVariantMap& shareInfo);
    void positionShareUpdated(const QVariantMap& posInfo);
    void positionShareRemoved(const QString& uri, const QString& accountId);
    void openNewMap();
    void closeMap(const QString& key);
    void pinMapSignal(const QString& key);
    void unPinMapSignal(const QString& key);
    void localPositionReceived(const QString& accountId, const QString& peerId, const QString& body);
    void makeVisibleSharingButton(const QString& accountId);
    void sendCountdownUpdate(const QString key, const int remainingTime);

protected:
    QString getAvatar(const QString& accountId, const QString& peerId);
    QVariantMap parseJsonPosition(const QString& accountId,
                                  const QString& peerId,
                                  const QString& body);
    void addPositionToMap(PositionKey key, QVariantMap position);
    void addPositionToMemory(PositionKey key, QVariantMap positionReceived);
    void updatePositionInMemory(PositionKey key, QVariantMap positionReceived);
    void removePositionFromMemory(PositionKey key, QVariantMap positionReceived);
    void positionWatchDog();
    void startPositionTimers(int timeSharing);
    void stopPositionTimers(PositionKey key = {});
    bool isNewMessageTriggersMap(bool endSharing, const QString& uri, const QString& accountId);
    void countdownUpdate();
    void sendStopMessage(QString accountId = "", const QString convId = "");

    Q_INVOKABLE void connectAccountModel();
    Q_INVOKABLE void pinMap(const QString& key);
    Q_INVOKABLE void unPinMap(const QString& key);
    Q_INVOKABLE void setMapActive(const QString& key);
    Q_INVOKABLE void setMapInactive(const QString& key);
    Q_INVOKABLE bool isMapActive(const QString& key);
    Q_INVOKABLE void sharePosition(int maximumTime, const QString& accountId, const QString& convId);
    Q_INVOKABLE void stopSharingPosition(const QString& accountId = "", const QString& convId = "");

    Q_INVOKABLE void startPositioning();
    Q_INVOKABLE void stopPositioning();

    Q_INVOKABLE bool isPositionSharedToConv(const QString& accountId, const QString& convUid);
    Q_INVOKABLE bool isConvSharingPosition(const QString& accountId, const QString& convUri);

    Q_INVOKABLE void loadPreviousLocations(const QString& accountId);
    Q_INVOKABLE QString getmapTitle(const QString& accountId, const QString& convId = "");

private Q_SLOTS:
    void onPositionErrorReceived(const QString error);
    void onNewPosition(const QString& body);
    void onPositionReceived(const QString& accountId,
                            const QString& peerId,
                            const QString& body,
                            const uint64_t& timestamp,
                            const QString& daemonId);
    void sendPosition(const QString& body, bool triggersLocalPosition = true);
    void onWatchdogTimeout();
    void showNotification(const QString& accountId, const QString& convId, const QString& from);
    void onNewConversation();
    void onNewAccount();

private:
    SystemTray* systemTray_;
    std::unique_ptr<Positioning> localPositioning_;
    QMap<PositionKey, int> mapTimerCountDown_;
    QTimer* countdownTimer_ = nullptr;
    // map of all shared position by peers
    QMap<PositionKey, PositionObject*> objectListSharingUris_;
    // list of all the peers the user is sharing position to
    QList<PositionKey> positionShareConvIds_;
    QMutex mapStatusMutex_;
    AppSettingsManager* settingsManager_;
};
