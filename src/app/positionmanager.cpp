#include "positionmanager.h"

#include "appsettingsmanager.h"

#include "qtutils.h"
#include <QApplication>
#include <QBuffer>
#include <QList>
#include <QTime>
#include <QJsonDocument>
#include <QImageReader>

PositionManager::PositionManager(AppSettingsManager* settingsManager,
                                 SystemTray* systemTray,
                                 LRCInstance* instance,
                                 QObject* parent)
    : QmlAdapterBase(instance, parent)
    , systemTray_(systemTray)
    , settingsManager_(settingsManager)
{
    countdownTimer_ = new QTimer(this);
    connect(countdownTimer_, &QTimer::timeout, this, &PositionManager::countdownUpdate);
    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &PositionManager::onNewConversation,
            Qt::UniqueConnection);
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &PositionManager::onNewAccount,
            Qt::UniqueConnection);
    connect(
        this,
        &PositionManager::localPositionReceived,
        this,
        [this](const QString& accountId, const QString& peerId, const QString& body) {
            onPositionReceived(accountId, peerId, body, -1, "");
        },
        Qt::QueuedConnection);

    localPositioning_.reset(new Positioning());
    connectAccountModel();
}

void
PositionManager::connectAccountModel()
{
    QObject::connect(&lrcInstance_->accountModel(),
                     &AccountModel::newPosition,
                     this,
                     &PositionManager::onPositionReceived,
                     Qt::UniqueConnection);
}

void
PositionManager::startPositioning()
{
    if (localPositioning_)
        localPositioning_->start();

    connect(localPositioning_.get(),
            &Positioning::positioningError,
            this,
            &PositionManager::onPositionErrorReceived,
            Qt::UniqueConnection);
    connect(
        localPositioning_.get(),
        &Positioning::newPosition,
        this,
        [this](const QString& body) { sendPosition(body, true); },
        Qt::UniqueConnection);
}
void
PositionManager::stopPositioning()
{
    if (localPositioning_)
        localPositioning_->stop();
}

bool
PositionManager::isConvSharingPosition(const QString& accountId, const QString& convUri)
{
    const auto& convParticipants = lrcInstance_->getConversationFromConvUid(convUri)
                                       .participantsUris();
    Q_FOREACH (const auto& id, convParticipants) {
        if (id != lrcInstance_->getCurrentAccountInfo().profileInfo.uri) {
            if (objectListSharingUris_.contains(PositionKey {accountId, id})) {
                return true;
            }
        }
    }
    return false;
}

void
PositionManager::loadPreviousLocations(QString& accountId)
{
    QVariantMap shareInfo;
    for (auto it = objectListSharingUris_.begin(); it != objectListSharingUris_.end(); it++) {
        if (it.key().first == accountId) {
            QJsonObject jsonObj;
            jsonObj.insert("type", QJsonValue("Position"));
            jsonObj.insert("lat", it.value()->getLatitude().toString());
            jsonObj.insert("long", it.value()->getLongitude().toString());
            QJsonDocument doc(jsonObj);
            QString strJson(doc.toJson(QJsonDocument::Compact));
            // parse the position from json
            QVariantMap positionReceived = parseJsonPosition(it.key().first,
                                                             it.key().second,
                                                             strJson);
            addPositionToMap(it.key(), positionReceived);
        }
    }
}

QString
PositionManager::getmapTitle(QString& accountId, QString convId)
{
    if (!convId.isEmpty() && !accountId.isEmpty()) {
        return lrcInstance_->getAccountInfo(accountId).conversationModel->title(convId);
    }

    if (!accountId.isEmpty()) {
        return lrcInstance_->accountModel().bestNameForAccount(accountId);
    }
    return {};
}

bool
PositionManager::isPositionSharedToConv(const QString& accountId, const QString& convUid)
{
    if (positionShareConvIds_.length()) {
        auto iter = std::find(positionShareConvIds_.begin(),
                              positionShareConvIds_.end(),
                              PositionKey {accountId, convUid});
        return (iter != positionShareConvIds_.end());
    }
    return false;
}

void
PositionManager::sendPosition(const QString& body, bool triggersLocalPosition)
{
    // send position to positionShareConvIds_ participants
    try {
        Q_FOREACH (const auto& key, positionShareConvIds_) {
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(key.second, key.first);
            auto accountUri = lrcInstance_->getAccountInfo(key.first).profileInfo.uri;
            Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
                if (uri != accountUri) {
                    lrcInstance_->getAccountInfo(key.first)
                        .contactModel->sendDhtMessage(uri, body, APPLICATION_GEO, 1);
                }
            }
        }
    } catch (const std::exception& e) {
        qDebug() << Q_FUNC_INFO << e.what();
    }
    if (triggersLocalPosition) {
        // send own position to every account with an opened map
        QMutexLocker lk(&mapStatusMutex_);
        for (auto it = mapStatus_.begin(); it != mapStatus_.end(); it++) {
            Q_EMIT localPositionReceived(it.key(),
                                         lrcInstance_->getAccountInfo(it.key()).profileInfo.uri,
                                         body);
        }
    }
}

void
PositionManager::onWatchdogTimeout()
{
    QObject* obj = sender();
    auto it = std::find_if(objectListSharingUris_.cbegin(),
                           objectListSharingUris_.cend(),
                           [obj](const auto& it) { return it == obj; });
    if (it != objectListSharingUris_.cend()) {
        QString stopMsg("{\"type\":\"Stop\"}");
        onPositionReceived(it.key().first, it.key().second, stopMsg, -1, "");
        makeVisibleSharingButton(it.key().first);
    }
}

void
PositionManager::sharePosition(int maximumTime, QString accountId, QString convId)
{
    try {
        if (settingsManager_->getValue(Settings::Key::PositionShareLimit) == true)
            startPositionTimers(maximumTime);
        positionShareConvIds_.append(PositionKey {accountId, convId});
        set_positionShareConvIdsCount(positionShareConvIds_.size());
    } catch (...) {
        qDebug() << "Exception during sharePosition:";
    }
}

void
PositionManager::stopSharingPosition(QString accountId, const QString convId)
{
    QString stopMsg;
    PositionKey key = qMakePair(accountId, convId);
    stopMsg = "{\"type\":\"Stop\"}";
    if (accountId == "") {
        sendPosition(stopMsg, false);
        stopPositionTimers();
        positionShareConvIds_.clear();
    } else {
        if (convId == "") {
            for (auto it = positionShareConvIds_.begin(); it != positionShareConvIds_.end();) {
                if (it->first == accountId) {
                    key = qMakePair(accountId, it->second);
                    stopPositionTimers(key);
                    sendStopMessage(accountId, it->second);
                    it = positionShareConvIds_.erase(it);
                } else
                    ++it;
            }
        } else {
            stopPositionTimers(key);
            sendStopMessage(accountId, convId);
            auto iter = std::find(positionShareConvIds_.begin(),
                                  positionShareConvIds_.end(),
                                  PositionKey {accountId, convId});
            if (iter != positionShareConvIds_.end()) {
                positionShareConvIds_.remove(std::distance(positionShareConvIds_.begin(), iter));
            }
        }
    }
    if (!positionShareConvIds_.size())
        countdownTimer_->stop();
    set_positionShareConvIdsCount(positionShareConvIds_.size());
}

void
PositionManager::sendStopMessage(QString accountId, const QString convId)
{
    QString stopMsg;
    stopMsg = "{\"type\":\"Stop\"}";
    if (accountId != "" && convId != "") {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId, accountId);
        Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
            if (lrcInstance_->getCurrentAccountInfo().profileInfo.uri != uri) {
                lrcInstance_->getCurrentAccountInfo().contactModel->sendDhtMessage(uri,
                                                                                   stopMsg,
                                                                                   APPLICATION_GEO,
                                                                                   1);
            }
        }
    }
}

void
PositionManager::unPinMap(QString key)
{
    QMutexLocker lk(&mapStatusMutex_);
    if (mapStatus_.find(key) != mapStatus_.end()) {
        mapStatus_[key] = true;
        Q_EMIT mapStatusChanged();
        Q_EMIT unPinMapSignal(key);
    } else {
        qWarning() << "Error: Can't unpin a map that doesn't exist";
    }
}

void
PositionManager::pinMap(QString key)
{
    QMutexLocker lk(&mapStatusMutex_);
    if (mapStatus_.find(key) != mapStatus_.end()) {
        // map can be pined only if it's in the right account
        if (key == lrcInstance_->get_currentAccountId()) {
            mapStatus_[key] = false;
            lk.unlock();
            Q_EMIT mapStatusChanged();
            Q_EMIT pinMapSignal(key);
        } else {
            lk.unlock();
            setMapInactive(key);
        }
    }
}

void
PositionManager::setMapInactive(const QString key)
{
    QMutexLocker lk(&mapStatusMutex_);
    if (mapStatus_.find(key) != mapStatus_.end()) {
        mapStatus_.remove(key);
        Q_EMIT mapStatusChanged();
        Q_EMIT closeMap(key);
        if (!mapStatus_.size()) {
            stopPositioning();
        }
    } else {
        qWarning() << "Error: Can't set inactive a map that doesn't exists";
    }
}

void
PositionManager::setMapActive(QString key)
{
    if (mapStatus_.find(key) == mapStatus_.end()) {
        mapStatus_.insert(key, false);
        Q_EMIT mapStatusChanged();
        // creation on QML
        Q_EMIT openNewMap();

    } else {
        pinMap(key);
    }
}

QString
PositionManager::getAvatar(const QString& accountId, const QString& uri)
{
    QString avatarBase64;
    QByteArray ba;
    QBuffer bu(&ba);

    auto& accInfo = accountId == "" ? lrcInstance_->getCurrentAccountInfo()
                                    : lrcInstance_->getAccountInfo(accountId);
    auto currentAccountUri = accInfo.profileInfo.uri;
    if (currentAccountUri == uri || accountId.isEmpty()) {
        // use accountPhoto
        Utils::accountPhoto(lrcInstance_, accInfo.id).save(&bu, "PNG");
    } else {
        // use contactPhoto
        Utils::contactPhoto(lrcInstance_, uri).save(&bu, "PNG");
    }
    return ba.toBase64();
}

QVariantMap
PositionManager::parseJsonPosition(const QString& accountId,
                                   const QString& peerId,
                                   const QString& body)
{
    QJsonDocument temp = QJsonDocument::fromJson(body.toUtf8());
    QJsonObject jsonObject = temp.object();
    QVariantMap pos;

    for (auto i = jsonObject.begin(); i != jsonObject.end(); i++) {
        if (i.key() == "long")
            pos["long"] = i.value().toVariant();
        if (i.key() == "lat")
            pos["lat"] = i.value().toVariant();
        if (i.key() == "type")
            pos["type"] = i.value().toVariant();
        if (i.key() == "time")
            pos["time"] = i.value().toVariant();

        pos["author"] = peerId;
        pos["account"] = accountId;
    }
    return pos;
}

void
PositionManager::startPositionTimers(int timeSharing)
{
    PositionKey key;
    key.first = lrcInstance_->get_currentAccountId();
    key.second = lrcInstance_->get_selectedConvUid();
    mapTimerCountDown_[key] = timeSharing;
    countdownUpdate();
    countdownTimer_->start(1000);
}

void
PositionManager::stopPositionTimers(PositionKey key)
{
    // reset all timers
    if (key == PositionKey()) {
        mapTimerCountDown_.clear();
    } else {
        auto it = mapTimerCountDown_.find(key);
        if (it != mapTimerCountDown_.end()) {
            mapTimerCountDown_.erase(it);
        }
        if (!mapTimerCountDown_.size())
            countdownTimer_->stop();
    }
}

void
PositionManager::onPositionErrorReceived(const QString error)
{
    Q_EMIT positioningError(error);
}

void
PositionManager::showNotification(const QString& accountId,
                                  const QString& convId,
                                  const QString& from)
{
    QString bestName;
    if (from == lrcInstance_->getAccountInfo(accountId).profileInfo.uri)
        bestName = lrcInstance_->getAccountInfo(accountId).accountModel->bestNameForAccount(
            accountId);
    else
        bestName = lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(from);

    auto body = tr("%1 is sharing it's location").arg(bestName);
#ifdef Q_OS_LINUX
    auto contactPhoto = Utils::contactPhoto(lrcInstance_, from, QSize(50, 50), accountId);
    auto notifId = QString("%1;%2;%3").arg(accountId).arg(convId).arg(from);
    systemTray_->showNotification(notifId,
                                  tr("Location sharing"),
                                  body,
                                  NotificationType::CHAT,
                                  Utils::QImageToByteArray(contactPhoto));

#else
    auto onClicked = [this, accountId, convId] {
        Q_EMIT lrcInstance_->notificationClicked();
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId, accountId);
        if (convInfo.uid.isEmpty())
            return;
        lrcInstance_->selectConversation(convInfo.uid, accountId);
    };
    systemTray_->showNotification(body, from, onClicked);
#endif
}

void
PositionManager::onNewConversation()
{
    set_mapAutoOpening(true);
}

void
PositionManager::onNewAccount()
{
    QMutexLocker lk(&mapStatusMutex_);
    for (auto it = mapStatus_.begin(); it != mapStatus_.end();) {
        if (it.value() == false) {
            Q_EMIT closeMap(it.key());
            it = mapStatus_.erase(it);
            Q_EMIT mapStatusChanged();
        } else {
            it++;
        }
    }
}

bool
PositionManager::isNewMessageTriggersMap(bool endSharing,
                                         const QString& uri,
                                         const QString& accountId)
{
    QMutexLocker lk(&mapStatusMutex_);
    return !endSharing && (accountId == lrcInstance_->get_currentAccountId()) && mapAutoOpening_
           && (uri != lrcInstance_->getCurrentAccountInfo().profileInfo.uri)
           && (mapStatus_.find(accountId) == mapStatus_.end());
}

void
PositionManager::countdownUpdate()
{
    // First removal of timers and shared position
    auto end = std::find_if(mapTimerCountDown_.begin(),
                            mapTimerCountDown_.end(),
                            [](const auto& end) { return end == 0; });
    if (end != mapTimerCountDown_.end()) {
        Q_EMIT sendCountdownUpdate(end.key().first + "_" + end.key().second, end.value());
        stopSharingPosition(end.key().first, end.key().second);
    }
    // When removals are done, countdown can be updated
    for (auto it = mapTimerCountDown_.begin(); it != mapTimerCountDown_.end(); it++) {
        if (it.value() != 0) {
            Q_EMIT sendCountdownUpdate(it.key().first + "_" + it.key().second, it.value());
            it.value() -= 1000;
        }
    }
}

void
PositionManager::addPositionToMap(PositionKey key, QVariantMap position)
{
    // avatar only sent one time to qml, when a new position is added
    position["avatar"] = getAvatar(key.first, key.second);
    auto accountId = key.first;
    auto uri = key.second;
    auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
    QString bestName;

    if (uri == accountInfo.profileInfo.uri) {
        bestName = accountInfo.accountModel->bestNameForAccount(accountId);
    } else
        bestName = accountInfo.contactModel->bestNameForContact(uri);

    QString shorterAuthorName = bestName;
    shorterAuthorName.truncate(20);
    if (bestName != shorterAuthorName) {
        shorterAuthorName = shorterAuthorName + "…";
    }
    position["authorName"] = shorterAuthorName;
    Q_EMIT positionShareAdded(position);
}

void
PositionManager::addPositionToMemory(PositionKey key, QVariantMap positionReceived)
{
    // add the position to the list
    auto obj = new PositionObject(positionReceived["lat"], positionReceived["long"], this);
    objectListSharingUris_.insert(key, obj);

    // information for qml
    set_sharingUrisCount(objectListSharingUris_.size());

    // watchdog
    connect(obj,
            &PositionObject::timeout,
            this,
            &PositionManager::onWatchdogTimeout,
            Qt::DirectConnection);

    auto& accountId = key.first;
    auto& uri = key.second;
    // Add position to the current map if needed)
    addPositionToMap(key, positionReceived);

    // show notification
    if (accountId != "") {
        QMutexLocker lk(&mapStatusMutex_);
        if (mapStatus_.find(accountId) == mapStatus_.end()) {
            auto& convInfo = lrcInstance_->getConversationFromPeerUri(uri, accountId);
            if (!convInfo.uid.isEmpty()) {
                showNotification(accountId, convInfo.uid, uri);
            }
        }
    }
}

void
PositionManager::updatePositionInMemory(PositionKey key, QVariantMap positionReceived)
{
    auto it = objectListSharingUris_.find(key);
    if (it != objectListSharingUris_.end()) {
        if (it.value()) {
            // reset watchdog
            it.value()->resetWatchdog();
            // update position
            it.value()->updatePosition(positionReceived["lat"], positionReceived["long"]);
        } else {
            qWarning() << "error in PositionManager::updatePositionInMemory(), it.value() is null";
        }
    } else {
        qWarning()
            << "Error: A position intented to be updated while not in objectListSharingUris_ ";
    }

    // update position on the map (if needed)
    Q_EMIT positionShareUpdated(positionReceived);
}

void
PositionManager::removePositionFromMemory(PositionKey key, QVariantMap positionReceived)
{
    // Remove
    auto it = objectListSharingUris_.find(key);
    if (it != objectListSharingUris_.end()) {
        // free memory
        it.value()->deleteLater();
        // delete value
        objectListSharingUris_.erase(it);
        // update list count for qml
        set_sharingUrisCount(objectListSharingUris_.size());
    } else {
        qWarning()
            << "Error: A position intented to be removed while not in objectListSharingUris_ ";
        return;
    }
    // if needed, remove from map
    Q_EMIT positionShareRemoved(key.second, positionReceived["account"].toString());
    // close the map if you're not sharing and you don't receive position anymore
    if (!positionShareConvIds_.length()
        && ((sharingUrisCount_ == 1
             && objectListSharingUris_.begin().key().second
                    == lrcInstance_->getCurrentAccountInfo().profileInfo.uri)
            || sharingUrisCount_ == 0)) {
        setMapInactive(lrcInstance_->get_currentAccountId());
    }
}

void
PositionManager::onPositionReceived(const QString& accountId,
                                    const QString& peerId,
                                    const QString& body,
                                    const uint64_t& timestamp,
                                    const QString& daemonId)
{
    // handlers variables

    // parse the position from json
    QVariantMap positionReceived = parseJsonPosition(accountId, peerId, body);

    // is it a message that notify an end of position sharing
    auto endSharing = positionReceived["type"] == "Stop";

    // key to identify the peer
    auto key = PositionKey {accountId, peerId};

    // check if the position exists in all shared positions, even if not visible to the screen
    auto findPeerIdinAllPeers = objectListSharingUris_.find(key);

    // open the map on position reception if needed
    if (isNewMessageTriggersMap(endSharing, peerId, accountId)) {
        setMapActive(accountId);
    }

    // if the position already exists
    if (findPeerIdinAllPeers != objectListSharingUris_.end()) {
        if (endSharing)
            removePositionFromMemory(key, positionReceived);
        else
            updatePositionInMemory(key, positionReceived);

    } else {
        // It is the first time a position is received from this peer
        addPositionToMemory(key, positionReceived);
    }
}
