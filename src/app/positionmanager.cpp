#include "positionmanager.h"

#include "qtutils.h"

#include <QApplication>
#include <QBuffer>
#include <QList>
#include <QTime>
#include <QJsonDocument>
#include <QImageReader>

PositionManager::PositionManager(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
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
}

void
PositionManager::safeInit()
{
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this]() {
        connectConversationModel();
        localPositioning_->setUri(lrcInstance_->getCurrentAccountInfo().profileInfo.uri);
    });
    localPositioning_.reset(new Positioning(lrcInstance_->getCurrentAccountInfo().profileInfo.uri));
    connectConversationModel();
}

void
PositionManager::connectConversationModel()
{
    auto currentConversationModel = lrcInstance_->getCurrentConversationModel();

    QObject::connect(currentConversationModel,
                     &ConversationModel::newPosition,
                     this,
                     &PositionManager::onPositionReceived,
                     Qt::UniqueConnection);
}

void
PositionManager::startPositioning()
{
    sharingUris_.clear();

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

void
PositionManager::onOwnPositionReceived(const QString& peerId, const QString& body)
{
    try {
        Q_FOREACH (const auto& id, positionShareConvIds_) {
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(id);
            Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
                if (peerId != uri) {
                    lrcInstance_->getCurrentAccountInfo()
                        .contactModel->sendDhtMessage(uri, body, APPLICATION_GEO);
                }
            }
        }

    } catch (const std::exception& e) {
        qDebug() << Q_FUNC_INFO << e.what();
    }
}

void
PositionManager::sharePosition(int maximumTime)
{
    connect(localPositioning_.get(),
            &Positioning::newPosition,
            this,
            &PositionManager::onOwnPositionReceived,
            Qt::UniqueConnection);

    try {
        startPositionTimers(maximumTime);
        const auto convUid = lrcInstance_->get_selectedConvUid();
        positionShareConvIds_.append(convUid);
        Q_EMIT positionShareConvIdsChanged();
    } catch (...) {
        qDebug() << "Exception during sharePosition:";
    }
}

void
PositionManager::stopSharingPosition()
{
    localPositioning_->sendStopSharingMsg();
    stopPositionTimers();
    set_positionShareConvIds({});
}

void
PositionManager::setMapActive(bool state)
{
    set_isMapActive(state);
    Q_EMIT isMapActiveChanged();
}

QString
PositionManager::getAvatar(const QString& uri)
{
    QString avatarBase64;
    QByteArray ba;
    QBuffer bu(&ba);

    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    auto currentAccountUri = accInfo.profileInfo.uri;
    if (currentAccountUri == uri) {
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
PositionManager::onPositionReceived(const QString& peerId,
                                    const QString& body,
                                    const uint64_t& timestamp,
                                    const QString& daemonId)
{
    // only show shared positions from contacts in the current conversation
    const auto& convParticipants = lrcInstance_
                                       ->getConversationFromConvUid(
                                           lrcInstance_->get_selectedConvUid())
                                       .participantsUris();
    bool isPeerIdInConv = (std::find(convParticipants.begin(), convParticipants.end(), peerId)
                           != convParticipants.end());
    if (!isPeerIdInConv)
        return;

    QVariantMap newPosition = parseJsonPosition(body, peerId);
    auto getShareInfo = [&](bool update) -> QVariantMap {
        QVariantMap shareInfo;
        shareInfo["author"] = peerId;
        if (!update) {
            shareInfo["avatar"] = getAvatar(peerId);
        }
        shareInfo["long"] = newPosition["long"];
        shareInfo["lat"] = newPosition["lat"];
        return shareInfo;
    };
    auto endSharing = newPosition["type"] == "Stop";

    if (!endSharing) {
        // open map on position reception
        if (!isMapActive_ && mapAutoOpening_
            && peerId != lrcInstance_->getCurrentAccountInfo().profileInfo.uri) {
            set_isMapActive(true);
        }
    }
    auto iter = std::find(sharingUris_.begin(), sharingUris_.end(), peerId);
    if (iter == sharingUris_.end()) {
        // New share
        if (!endSharing) {
            sharingUris_.insert(peerId);
            Q_EMIT positionShareAdded(getShareInfo(false));
        }

    } else {
        // Update/remove existing
        if (endSharing) {
            // Remove (avoid self)
            if (peerId != lrcInstance_->getCurrentAccountInfo().profileInfo.uri) {
                sharingUris_.remove(peerId);
                Q_EMIT positionShareRemoved(peerId);
                // close the map if you're not sharing and the only remaining position is yours
                if (!positionShareConvIds_.length() && sharingUris_.size() == 1
                    && sharingUris_.contains(
                        lrcInstance_->getCurrentAccountInfo().profileInfo.uri)) {
                    set_isMapActive(false);
                }
            }
        } else {
            // Update
            Q_EMIT positionShareUpdated(getShareInfo(true));
        }
    }
}
