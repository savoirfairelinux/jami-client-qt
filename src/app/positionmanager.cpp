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
    connect(lrcInstance_, &LRCInstance::selectedConvUidChanged, [this]() {
        set_mapAutoOpening(true);
    });
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this]() {
        localPositioning_->setUri(lrcInstance_->getCurrentAccountInfo().profileInfo.uri);
    });
    set_isMapActive(false);
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
    currentConvSharingUris_.clear();
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
        QJsonObject jsonObj;
        jsonObj.insert("type", QJsonValue("Position"));
        jsonObj.insert("lat", it.value()->getLatitude().toString());
        jsonObj.insert("long", it.value()->getLongitude().toString());
        QJsonDocument doc(jsonObj);
        QString strJson(doc.toJson(QJsonDocument::Compact));
        onPositionReceived(it.key().first, it.key().second, strJson, -1, "");
    }
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
            QPair<QString, QString> {lrcInstance_->get_currentAccountId(), convUid});
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
    set_isMapActive(state);
    Q_EMIT isMapActiveChanged();
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
#ifdef Q_OS_LINUX
    auto contactPhoto = Utils::contactPhoto(lrcInstance_, from, QSize(50, 50), accountId);
    auto notifId = QString("%1;%2;%3").arg(accountId).arg(convId).arg(from);
    auto bestName = lrcInstance_->getAccountInfo(accountId).contactModel->bestNameForContact(from);
    systemTray_->showNotification(notifId,
                                  tr("Location sharing"),
                                  tr("%1 is sharing it's location").arg(bestName),
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
    systemTray_->showNotification(interaction.body, from, onClicked);
#endif
}

void
PositionManager::onPositionReceived(const QString& accountId,
                                    const QString& peerId,
                                    const QString& body,
                                    const uint64_t& timestamp,
                                    const QString& daemonId)
{
    // only show shared positions from contacts in the current conversation
    const auto& convParticipants = lrcInstance_
                                       ->getConversationFromConvUid(
                                           lrcInstance_->get_selectedConvUid())
                                       .participantsUris();
    // to know if the position received is from someone in the current conversation
    bool isPeerIdInConv = (std::find(convParticipants.begin(), convParticipants.end(), peerId)
                           != convParticipants.end());

    QVariantMap newPosition = parseJsonPosition(body, peerId);
    auto getShareInfo = [&](bool update) -> QVariantMap {
        QVariantMap shareInfo;
        shareInfo["author"] = peerId;
        if (!update) {
            shareInfo["avatar"] = getAvatar(accountId, peerId);
        }
        shareInfo["long"] = newPosition["long"];
        shareInfo["lat"] = newPosition["lat"];
        return shareInfo;
    };
    auto endSharing = newPosition["type"] == "Stop";

    auto key = QPair<QString, QString> {accountId, peerId};

    if (!endSharing) {
        // open map on position reception
        if (!isMapActive_ && mapAutoOpening_ && isPeerIdInConv
            && peerId != lrcInstance_->getCurrentAccountInfo().profileInfo.uri) {
            set_isMapActive(true);
        }
    }
    auto iter = std::find(currentConvSharingUris_.begin(), currentConvSharingUris_.end(), key);
    if (iter == currentConvSharingUris_.end()) {
        // New share
        if (!endSharing) {
            // list to save more information on position + watchdog
            auto it = objectListSharingUris_.find(key);
            auto isNewSharing = it == objectListSharingUris_.end();
            if (isNewSharing) {
                auto obj = new PositionObject(newPosition["lat"], newPosition["long"], this);

                objectListSharingUris_.insert(key, obj);
                set_sharingUrisCount(objectListSharingUris_.size());
                connect(obj,
                        &PositionObject::timeout,
                        this,
                        &PositionManager::onWatchdogTimeout,
                        Qt::DirectConnection);
            }

            if (isPeerIdInConv) {
                currentConvSharingUris_.insert(key);
                Q_EMIT positionShareAdded(getShareInfo(false));
            } else if (isNewSharing && accountId != "") {
                auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerId, accountId);
                if (!convInfo.uid.isEmpty()) {
                    showNotification(accountId, convInfo.uid, peerId);
                }
            }
            // stop sharing position
        } else {
            auto it = objectListSharingUris_.find(key);
            if (it != objectListSharingUris_.end()) {
                it.value()->deleteLater();
                objectListSharingUris_.erase(it);
                set_sharingUrisCount(objectListSharingUris_.size());
            }
        }
    } else {
        // Update/remove existing
        if (endSharing) {
            // Remove
            auto it = objectListSharingUris_.find(key);
            if (it != objectListSharingUris_.end()) {
                it.value()->deleteLater();
                objectListSharingUris_.erase(it);
                set_sharingUrisCount(objectListSharingUris_.size());
            }
            if (isPeerIdInConv) {
                currentConvSharingUris_.remove(key);
                Q_EMIT positionShareRemoved(peerId);
                // close the map if you're not sharing and you don't receive position anymore
                if (!positionShareConvIds_.length()
                    && ((sharingUrisCount_ == 1
                         && objectListSharingUris_.contains(QPair<QString, QString> {
                             "", lrcInstance_->getCurrentAccountInfo().profileInfo.uri}))
                        || sharingUrisCount_ == 0)) {
                    set_isMapActive(false);
                }
            }
        } else {
            // Update
            if (isPeerIdInConv)
                Q_EMIT positionShareUpdated(getShareInfo(true));
            // reset watchdog

            auto it = objectListSharingUris_.find(key);
            if (it != objectListSharingUris_.end()) {
                it.value()->resetWatchdog();
            }
        }
    }
}
