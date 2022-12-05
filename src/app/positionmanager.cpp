#include "positionmanager.h"

#include "qtutils.h"

#include <QApplication>
#include <QBuffer>
#include <QList>
#include <QTime>
#include <QJsonDocument>
#include <QImageReader>

PositionManager::PositionManager(SystemTray* systemTray, LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
    , systemTray_(systemTray)
{
    timerTimeLeftSharing_ = new QTimer(this);
    timerStopSharing_ = new QTimer(this);
    connect(timerTimeLeftSharing_, &QTimer::timeout, [=] {
        set_timeSharingRemaining(timerStopSharing_->remainingTime());
    });
    connect(timerStopSharing_, &QTimer::timeout, [=] { stopSharingPosition(); });
    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &PositionManager::onNewConversation);
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &PositionManager::onNewAccount);
}

void
PositionManager::safeInit()
{
    localPositioning_.reset(new Positioning(lrcInstance_->getCurrentAccountInfo().profileInfo.uri));
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
            &Positioning::newPosition,
            this,
            &PositionManager::onPositionReceived,
            Qt::UniqueConnection);
    connect(localPositioning_.get(),
            &Positioning::positioningError,
            this,
            &PositionManager::onPositionErrorReceived,
            Qt::UniqueConnection);
}

void
PositionManager::stopPositioning()
{
    if (localPositioning_)
        localPositioning_->stop();
}

QString
PositionManager::getSelectedConvId()
{
    return lrcInstance_->get_selectedConvUid();
}

bool
PositionManager::isConvSharingPosition(const QString& convUri)
{
    const auto& convParticipants = lrcInstance_->getConversationFromConvUid(convUri)
                                       .participantsUris();
    Q_FOREACH (const auto& id, convParticipants) {
        if (id != lrcInstance_->getCurrentAccountInfo().profileInfo.uri) {
            if (objectListSharingUris_.contains(
                    QPair<QString, QString> {lrcInstance_->get_currentAccountId(), id})) {
                return true;
            }
        }
    }
    return false;
}

void
PositionManager::loadPreviousLocations()
{
    QVariantMap shareInfo;
    for (auto it = objectListSharingUris_.begin(); it != objectListSharingUris_.end(); it++) {
        if (isUriInCurrentMap(it.key().second)) {
            QJsonObject jsonObj;
            jsonObj.insert("type", QJsonValue("Position"));
            jsonObj.insert("lat", it.value()->getLatitude().toString());
            jsonObj.insert("long", it.value()->getLongitude().toString());
            QJsonDocument doc(jsonObj);
            QString strJson(doc.toJson(QJsonDocument::Compact));
            // parse the position from json
            QVariantMap positionReceived = parseJsonPosition(strJson, it.key().second);
            addPositionToMap(it.key(), positionReceived);
        }
    }
}

QString
PositionManager::getmapConvTitle()
{
    return lrcInstance_->getAccountInfo(getsharedAccountId())
        .conversationModel->title(getsharedConvId());
}

QString
PositionManager::getsharedConvId()
{
    if (isMapUnpin())
        return mapsharedConversation_.first;
    return lrcInstance_->get_selectedConvUid();
}

QString
PositionManager::getsharedAccountId()
{
    if (isMapUnpin())
        return mapsharedConversation_.second;
    return lrcInstance_->get_currentAccountId();
}

void
PositionManager::clearUnpinMapsharePosition()
{
    mapsharedConversation_.first.clear();
    mapsharedConversation_.second.clear();
}

bool
PositionManager::isPositionSharedToConv(const QString& convUid)
{
    if (positionShareConvIds_.length()) {
        auto iter = std::find(positionShareConvIds_.begin(),
                              positionShareConvIds_.end(),
                              QPair<QString, QString> {lrcInstance_->get_currentAccountId(),
                                                       convUid});
        return (iter != positionShareConvIds_.end());
    }
    return false;
}

void
PositionManager::sendPosition(const QString& body)
{
    try {
        Q_FOREACH (const auto& key, positionShareConvIds_) {
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(key.second, key.first);
            auto accountUri = lrcInstance_->getAccountInfo(key.first).profileInfo.uri;
            Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
                if (uri != accountUri) {
                    lrcInstance_->getAccountInfo(key.first)
                        .contactModel->sendDhtMessage(uri, body, APPLICATION_GEO);
                }
            }
        }
    } catch (const std::exception& e) {
        qDebug() << Q_FUNC_INFO << e.what();
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
    }
}

void
PositionManager::sharePosition(int maximumTime)
{
    connect(
        localPositioning_.get(),
        &Positioning::newPosition,
        this,
        [&](const QString&, const QString&, const QString& body, const uint64_t&, const QString&) {
            sendPosition(body);
        },
        Qt::UniqueConnection);

    try {
        startPositionTimers(maximumTime);
        const auto convUid = lrcInstance_->get_selectedConvUid();
        positionShareConvIds_.append(
            QPair<QString, QString> {getsharedAccountId(), getsharedConvId()});
        set_positionShareConvIdsCount(positionShareConvIds_.size());
    } catch (...) {
        qDebug() << "Exception during sharePosition:";
    }
}

void
PositionManager::stopSharingPosition(const QString convId)
{
    QString stopMsg;
    stopMsg = "{\"type\":\"Stop\"}";
    if (convId == "") {
        sendPosition(stopMsg);
        stopPositionTimers();
        positionShareConvIds_.clear();
        set_positionShareConvIdsCount(positionShareConvIds_.size());
    } else {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
        Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
            if (lrcInstance_->getCurrentAccountInfo().profileInfo.uri != uri) {
                lrcInstance_->getCurrentAccountInfo().contactModel->sendDhtMessage(uri,
                                                                                   stopMsg,
                                                                                   APPLICATION_GEO);
            }
        }
        auto iter = std::find(positionShareConvIds_.begin(),
                              positionShareConvIds_.end(),
                              QPair<QString, QString> {lrcInstance_->get_currentAccountId(),
                                                       convId});
        if (iter != positionShareConvIds_.end()) {
            positionShareConvIds_.remove(std::distance(positionShareConvIds_.begin(), iter));
        }
        set_positionShareConvIdsCount(positionShareConvIds_.size());
    }
}

void
PositionManager::setMapActive(bool state)
{
    if (!isMapActive_ && state) {
        set_isMapActive(true);
        Q_EMIT isMapActiveChanged();

    } else if (!state) {
        set_isMapActive(false);
        Q_EMIT isMapActiveChanged();
        stopPositioning();
    }
}

void
PositionManager::lockMapConv(QString convId, QString accountId)
{
    mapsharedConversation_.first = convId;
    mapsharedConversation_.second = accountId;
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
PositionManager::parseJsonPosition(const QString& body, const QString& peerId)
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
    }
    return pos;
}

void
PositionManager::startPositionTimers(int timeSharing)
{
    set_timeSharingRemaining(timeSharing);
    timerTimeLeftSharing_->start(1000);
    timerStopSharing_->start(timeSharing);
}

void
PositionManager::stopPositionTimers()
{
    set_timeSharingRemaining(0);
    timerTimeLeftSharing_->stop();
    timerStopSharing_->stop();
}

bool
PositionManager::isMapUnpin()
{
    return !mapsharedConversation_.first.isEmpty();
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
    auto bestName = lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(from);
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
    if (!isMapUnpin()) {
        set_mapAutoOpening(true);
        setMapActive(false);
    } else {
        set_mapAutoOpening(false);
    }
}

void
PositionManager::onNewAccount()
{
    if (!isMapUnpin()) {
        if (localPositioning_)
            localPositioning_->setUri(lrcInstance_->getCurrentAccountInfo().profileInfo.uri);
        setMapActive(false);
    }
}

bool
PositionManager::isNewMessageTriggersMap(bool endSharing, bool isPeerIdInConv, const QString& uri)
{
    return !endSharing && isPeerIdInConv && !isMapActive_ && mapAutoOpening_
           && (uri != lrcInstance_->getCurrentAccountInfo().profileInfo.uri);
}

void
PositionManager::addPositionToMap(QPair<QString, QString> key, QVariantMap position)
{
    // avatar only sent one time to qml, when a new position is added
    position["avatar"] = getAvatar(key.first, key.second);
    Q_EMIT positionShareAdded(position);
}

void
PositionManager::addPositionToMemory(bool mapChange,
                                     QPair<QString, QString> key,
                                     QVariantMap positionReceived)
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

    // Add position to the current map (if needed)
    if (mapChange)
        addPositionToMap(key, positionReceived);

    // show notification
    if (key.first != "") {
        auto& convInfo = lrcInstance_->getConversationFromPeerUri(key.second, key.first);
        if (!convInfo.uid.isEmpty()) {
            showNotification(key.first, convInfo.uid, key.second);
        }
    }
}

void
PositionManager::updatePositionInMemory(bool mapChange,
                                        QPair<QString, QString> key,
                                        QVariantMap positionReceived)
{
    auto it = objectListSharingUris_.find(key);
    if (it != objectListSharingUris_.end()) {
        // reset watchdog
        it.value()->resetWatchdog();
        // update position
        it.value()->updatePosition(positionReceived["lat"], positionReceived["long"]);
    } else {
        qWarning()
            << "Error: A position intented to be updated while not in objectListSharingUris_ ";
    }

    // update position on the map (if needed)
    if (mapChange)
        Q_EMIT positionShareUpdated(positionReceived);
}

void
PositionManager::removePositionFromMemory(bool mapChange,
                                          QPair<QString, QString> key,
                                          QVariantMap positionReceived)
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
    }
    // if needed, remove from map
    if (mapChange)
        Q_EMIT positionShareRemoved(key.second);

    // close the map if you're not sharing and you don't receive position anymore
    if (!positionShareConvIds_.length()
        && ((sharingUrisCount_ == 1
             && objectListSharingUris_.contains(
                 QPair<QString, QString> {"",
                                          lrcInstance_->getCurrentAccountInfo().profileInfo.uri}))
            || sharingUrisCount_ == 0)) {
        setMapActive(false);
    }
}

bool
PositionManager::isUriInCurrentMap(const QString& uri)
{
    // Get the contacts from the conversation of the map
    const auto& convParticipants = lrcInstance_
                                       ->getConversationFromConvUid(getsharedConvId(),
                                                                    getsharedAccountId())
                                       .participantsUris();
    // to know if the position received is from someone in the conversation of the map
    bool isPeerIdInConv = (std::find(convParticipants.begin(), convParticipants.end(), uri)
                           != convParticipants.end());
    return isPeerIdInConv;
}

void
PositionManager::onPositionReceived(const QString& accountId,
                                    const QString& peerId,
                                    const QString& body,
                                    const uint64_t& timestamp,
                                    const QString& daemonId)
{
    // handlers variables

    // is the message received from a peer in the current map
    bool isPeerIdInCurrentMap = isUriInCurrentMap(peerId);

    // parse the position from json
    QVariantMap positionReceived = parseJsonPosition(body, peerId);

    // is it a message that notify an end of position sharing
    auto endSharing = positionReceived["type"] == "Stop";

    // key to identify the peer
    auto key = QPair<QString, QString> {accountId, peerId};

    // check if the position exists in all shared positions, even if not visible to the screen
    auto findPeerIdinAllPeers = objectListSharingUris_.find(key);

    // open the map on position reception if needed
    if (isNewMessageTriggersMap(endSharing, isPeerIdInCurrentMap, peerId))
        setMapActive(true);

    // if the position already exists
    if (findPeerIdinAllPeers != objectListSharingUris_.end()) {
        if (endSharing)
            removePositionFromMemory(isPeerIdInCurrentMap, key, positionReceived);
        else
            updatePositionInMemory(isPeerIdInCurrentMap, key, positionReceived);

    } else {
        // It is the first time a position is received from this peer
        addPositionToMemory(isPeerIdInCurrentMap, key, positionReceived);
    }
}
