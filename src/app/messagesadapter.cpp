/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
 * Author: Olivier Soldano <olivier.soldano@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#include "messagesadapter.h"

#include "appsettingsmanager.h"
#include "qtutils.h"
#include <api/datatransfermodel.h>

#include <QApplication>
#include <QBuffer>
#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QList>
#include <QMimeData>
#include <QMimeDatabase>
#include <QUrl>
#include <QtMath>
#include <QRegExp>
#include <QJsonDocument>

MessagesAdapter::MessagesAdapter(AppSettingsManager* settingsManager,
                                 PreviewEngine* previewEngine,
                                 LRCInstance* instance,
                                 QObject* parent)
    : QmlAdapterBase(instance, parent)
    , settingsManager_(settingsManager)
    , previewEngine_(previewEngine)
    , mediaInteractions_(std::make_unique<MessageListModel>())
{
    QList<QVariantMap> testPosList;
    QVariantMap testPos;
    testPos["long"] = 151.209900;
    testPos["lat"] = -33.865143;
    testPosList.append(testPos);
    connect(lrcInstance_, &LRCInstance::selectedConvUidChanged, [this]() {
        set_replyToId("");
        set_editId("");
        const QString& convId = lrcInstance_->get_selectedConvUid();
        const auto& conversation = lrcInstance_->getConversationFromConvUid(convId);
        ownPosition = new Positioning(lrcInstance_->getCurrentAccountInfo().profileInfo.uri);
        //            lrcInstance_->getCurrentAccountInfo().conversationModel->peersForConversation(convId).at(0));
        set_messageListModel(QVariant::fromValue(conversation.interactions.get()));
        set_currentConvComposingList(conversationTypersUrlToName(conversation.typers));
    });
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::newPosition,
            this,
            &MessagesAdapter::onPositionReceived);
    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessagesAdapter::onPreviewInfoReady);
    connect(previewEngine_, &PreviewEngine::linkified, this, &MessagesAdapter::onMessageLinkified);
    set_isMapActive(false);
}

void
MessagesAdapter::startPositioning()
{
    ownPosition->startPositioning();
    connect(ownPosition, &Positioning::newPos, this, &MessagesAdapter::onPositionReceived);
}
void
MessagesAdapter::stopPositioning()
{
    ownPosition->stopPositioning();
}
void
MessagesAdapter::onOwnPositionReceived(const QString& peerId, const QString& body)
{
    try {
        Q_FOREACH (const auto& id, positionShareConvIds_) {
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(id);
            Q_FOREACH (const QString& uri, convInfo.participantsUris()) {
                if (peerId != uri) {
                    lrcInstance_->getCurrentAccountInfo()
                        .contactModel->sendDhtMessage(uri, body, "application/geo");
                    qWarning() << "share to: " << uri;
                }
            }
        }

    } catch (const std::exception& e) {
        qDebug() << Q_FUNC_INFO << e.what();
    }
}

void
MessagesAdapter::sharePosition()
{
    qWarning() << "sharing position";
    connect(ownPosition, &Positioning::newPos, this, &MessagesAdapter::onOwnPositionReceived);
    try {
        const auto convUid = lrcInstance_->get_selectedConvUid();
        positionShareConvIds_.append(convUid);
    } catch (...) {
        qDebug() << "Exception during sharePosition:";
    }
    qWarning() << positionShareConvIds_;
}
void
MessagesAdapter::stopSharingPosition()
{
    positionShareConvIds_.clear();
}

void
MessagesAdapter::safeInit()
{
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, [this]() {
        connectConversationModel();
    });
    connectConversationModel();
}

void
MessagesAdapter::setupChatView(const QVariantMap& convInfo)
{
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    auto convId = convInfo["convId"].toString();
    if (convInfo["isSwarm"].toBool()) {
        convModel->loadConversationMessages(convId, loadChunkSize_);
    }

    // TODO: current conv observe
    Q_EMIT newMessageBarPlaceholderText(convInfo["title"].toString());
}

void
MessagesAdapter::loadMoreMessages()
{
    auto accountId = lrcInstance_->get_currentAccountId();
    auto convId = lrcInstance_->get_selectedConvUid();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId, accountId);
    if (convInfo.isSwarm()) {
        auto* convModel = lrcInstance_->getCurrentConversationModel();
        convModel->loadConversationMessages(convId, loadChunkSize_);
    }
}

void
MessagesAdapter::loadConversationUntil(const QString& to)
{
    if (auto* model = messageListModel_.value<MessageListModel*>()) {
        auto idx = model->indexOfMessage(to);
        if (idx == -1) {
            auto accountId = lrcInstance_->get_currentAccountId();
            auto convId = lrcInstance_->get_selectedConvUid();
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId, accountId);
            if (convInfo.isSwarm()) {
                auto* convModel = lrcInstance_->getCurrentConversationModel();
                convModel->loadConversationUntil(convId, to);
            }
        }
    }
}

void
MessagesAdapter::connectConversationModel()
{
    auto currentConversationModel = lrcInstance_->getCurrentConversationModel();

    QObject::connect(currentConversationModel,
                     &ConversationModel::newInteraction,
                     this,
                     &MessagesAdapter::onNewInteraction,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &ConversationModel::conversationMessagesLoaded,
                     this,
                     &MessagesAdapter::onConversationMessagesLoaded,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &ConversationModel::composingStatusChanged,
                     this,
                     &MessagesAdapter::onComposingStatusChanged,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &ConversationModel::messagesFoundProcessed,
                     this,
                     &MessagesAdapter::onMessagesFoundProcessed,
                     Qt::UniqueConnection);
}

void
MessagesAdapter::sendConversationRequest()
{
    lrcInstance_->makeConversationPermanent();
}

void
MessagesAdapter::sendMessage(const QString& message)
{
    try {
        const auto convUid = lrcInstance_->get_selectedConvUid();
        lrcInstance_->getCurrentConversationModel()->sendMessage(convUid, message, replyToId_);
        set_replyToId("");
    } catch (...) {
        qDebug() << "Exception during sendMessage:" << message;
    }
}

void
MessagesAdapter::editMessage(const QString& convId, const QString& newBody, const QString& messageId)
{
    try {
        const auto convUid = lrcInstance_->get_selectedConvUid();
        auto editId = !messageId.isEmpty() ? messageId : editId_;
        if (editId.isEmpty()) {
            qWarning("No message to edit");
            return;
        }
        lrcInstance_->getCurrentConversationModel()->editMessage(convId, newBody, editId);
        set_editId("");
    } catch (...) {
        qDebug() << "Exception during message edition:" << messageId;
    }
}

void
MessagesAdapter::sendFile(const QString& message)
{
    QFileInfo fi(message);
    QString fileName = fi.fileName();
    try {
        auto convUid = lrcInstance_->get_selectedConvUid();
        lrcInstance_->getCurrentConversationModel()->sendFile(convUid, message, fileName);
    } catch (...) {
        qDebug() << "Exception during sendFile";
    }
}

void
MessagesAdapter::retryInteraction(const QString& interactionId)
{
    lrcInstance_->getCurrentConversationModel()
        ->retryInteraction(lrcInstance_->get_selectedConvUid(), interactionId);
}

void
MessagesAdapter::copyToDownloads(const QString& interactionId, const QString& displayName)
{
    auto downloadDir = lrcInstance_->accountModel().downloadDirectory;
    if (auto accInfo = &lrcInstance_->getCurrentAccountInfo())
        accInfo->dataTransferModel->copyTo(lrcInstance_->get_currentAccountId(),
                                           lrcInstance_->get_selectedConvUid(),
                                           interactionId,
                                           downloadDir,
                                           displayName);
}

void
MessagesAdapter::deleteInteraction(const QString& interactionId)
{
    lrcInstance_->getCurrentConversationModel()
        ->clearInteractionFromConversation(lrcInstance_->get_selectedConvUid(), interactionId);
}

void
MessagesAdapter::openUrl(const QString& url)
{
    if (!QDesktopServices::openUrl(url)) {
        qDebug() << "Couldn't open url: " << url;
    }
}

void
MessagesAdapter::openDirectory(const QString& path)
{
    QString p = path;
    QFileInfo f(p);
    if (f.exists()) {
        if (!f.isDir())
            p = f.dir().absolutePath();
        QString url;
        if (!p.startsWith("file:/"))
            url = "file:///" + p;
        else
            url = p;
        openUrl(url);
    }
}

void
MessagesAdapter::acceptFile(const QString& interactionId)
{
    auto convUid = lrcInstance_->get_selectedConvUid();
    lrcInstance_->getCurrentConversationModel()->acceptTransfer(convUid, interactionId);
}

void
MessagesAdapter::cancelFile(const QString& interactionId)
{
    const auto convUid = lrcInstance_->get_selectedConvUid();
    lrcInstance_->getCurrentConversationModel()->cancelTransfer(convUid, interactionId);
}

void
MessagesAdapter::onPaste()
{
    const QMimeData* mimeData = QApplication::clipboard()->mimeData();

    if (mimeData->hasImage()) {
        // Save temp data into a temp file.
        QPixmap pixmap = qvariant_cast<QPixmap>(mimeData->imageData());

        auto img_name_hash
            = QCryptographicHash::hash(QString::number(pixmap.cacheKey()).toLocal8Bit(),
                                       QCryptographicHash::Sha1);
        QString fileName = "img_" + QString(img_name_hash.toHex()) + ".png";
        QString path = QDir::temp().filePath(fileName);

        if (!pixmap.save(path, "PNG")) {
            qDebug().noquote() << "Errors during QPixmap save"
                               << "\n";
            return;
        }

        Q_EMIT newFilePasted(path);
    } else if (mimeData->hasUrls()) {
        QList<QUrl> urlList = mimeData->urls();

        // Extract the local paths of the files.
        for (int i = 0; i < urlList.size(); ++i) {
            // Trim file:// or file:/// from url.
            QString filePath = urlList.at(i).toString().remove(
                QRegularExpression("^file:\\/{2,3}"));
            Q_EMIT newFilePasted(filePath);
        }
    } else {
        // Treat as text content, make chatview.js handle in order to
        // avoid string escape problems
        Q_EMIT newTextPasted();
    }
}

QString
MessagesAdapter::getStatusString(int status)
{
    switch (static_cast<interaction::Status>(status)) {
    case interaction::Status::SENDING:
        return QObject::tr("Sending");
    case interaction::Status::FAILURE:
        return QObject::tr("Failure");
    case interaction::Status::SUCCESS:
        return QObject::tr("Sent");
    case interaction::Status::TRANSFER_CREATED:
        return QObject::tr("Connecting");
    case interaction::Status::TRANSFER_ACCEPTED:
        return QObject::tr("Accept");
    case interaction::Status::TRANSFER_CANCELED:
        return QObject::tr("Canceled");
    case interaction::Status::TRANSFER_ERROR:
    case interaction::Status::TRANSFER_UNJOINABLE_PEER:
        return QObject::tr("Unable to make contact");
    case interaction::Status::TRANSFER_ONGOING:
        return QObject::tr("Ongoing");
    case interaction::Status::TRANSFER_AWAITING_PEER:
        return QObject::tr("Waiting for contact");
    case interaction::Status::TRANSFER_AWAITING_HOST:
        return QObject::tr("Incoming transfer");
    case interaction::Status::TRANSFER_TIMEOUT_EXPIRED:
        return QObject::tr("Timed out waiting for contact");
    case interaction::Status::TRANSFER_FINISHED:
        return QObject::tr("Finished");
    default:
        return {};
    }
}

QVariantMap
MessagesAdapter::getTransferStats(const QString& msgId, int status)
{
    Q_UNUSED(status)
    auto convModel = lrcInstance_->getCurrentConversationModel();
    lrc::api::datatransfer::Info info = {};
    convModel->getTransferInfo(lrcInstance_->get_selectedConvUid(), msgId, info);
    return {{"totalSize", qint64(info.totalSize)}, {"progress", qint64(info.progress)}};
}

QVariant
MessagesAdapter::dataForInteraction(const QString& interactionId, int role) const
{
    if (auto* model = messageListModel_.value<MessageListModel*>()) {
        auto idx = model->indexOfMessage(interactionId);
        if (idx != -1)
            return model->data(idx, role);
    }
    return {};
}

int
MessagesAdapter::getIndexOfMessage(const QString& interactionId) const
{
    if (auto* model = messageListModel_.value<MessageListModel*>()) {
        return model->indexOfMessage(interactionId);
    }
    return {};
}

void
MessagesAdapter::userIsComposing(bool isComposing)
{
    if (!settingsManager_->getValue(Settings::Key::EnableTypingIndicator).toBool()
        || lrcInstance_->get_selectedConvUid().isEmpty()) {
        return;
    }
    lrcInstance_->getCurrentConversationModel()->setIsComposing(lrcInstance_->get_selectedConvUid(),
                                                                isComposing);
}

void
MessagesAdapter::onNewInteraction(const QString& convUid,
                                  const QString& interactionId,
                                  const interaction::Info& interaction)
{
    Q_UNUSED(interactionId);
    try {
        if (convUid.isEmpty() || convUid != lrcInstance_->get_selectedConvUid()) {
            return;
        }
        auto accountId = lrcInstance_->get_currentAccountId();
        auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
        auto& convModel = accountInfo.conversationModel;
        convModel->clearUnreadInteractions(convUid);
        Q_EMIT newInteraction(interactionId, static_cast<int>(interaction.type));
    } catch (...) {
    }
}

void
MessagesAdapter::acceptInvitation(const QString& convId)
{
    auto conversationId = convId.isEmpty() ? lrcInstance_->get_selectedConvUid() : convId;
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    convModel->acceptConversationRequest(conversationId);
}

void
MessagesAdapter::refuseInvitation(const QString& convUid)
{
    const auto currentConvUid = convUid.isEmpty() ? lrcInstance_->get_selectedConvUid() : convUid;
    lrcInstance_->getCurrentConversationModel()->removeConversation(currentConvUid, false);
}

void
MessagesAdapter::blockConversation(const QString& convUid)
{
    const auto currentConvUid = convUid.isEmpty() ? lrcInstance_->get_selectedConvUid() : convUid;
    lrcInstance_->getCurrentConversationModel()->removeConversation(currentConvUid, true);
}

void
MessagesAdapter::unbanContact(int index)
{
    auto& accountInfo = lrcInstance_->getCurrentAccountInfo();
    auto bannedContactList = accountInfo.contactModel->getBannedContacts();
    auto it = bannedContactList.begin();
    std::advance(it, index);

    try {
        auto contactInfo = accountInfo.contactModel->getContact(*it);
        accountInfo.contactModel->addContact(contactInfo);
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
    }
}

void
MessagesAdapter::unbanConversation(const QString& convUid)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    try {
        const auto contactUri = accInfo.conversationModel->peersForConversation(convUid).at(0);
        auto contactInfo = accInfo.contactModel->getContact(contactUri);
        accInfo.contactModel->addContact(contactInfo);
    } catch (const std::out_of_range& e) {
        qDebug() << e.what();
    }
}

void
MessagesAdapter::clearConversationHistory(const QString& accountId, const QString& convUid)
{
    lrcInstance_->getAccountInfo(accountId).conversationModel->clearHistory(convUid);
}

void
MessagesAdapter::removeConversation(const QString& convUid)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    accInfo.conversationModel->removeConversation(convUid);
}

void
MessagesAdapter::removeConversationMember(const QString& convUid, const QString& memberUri)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    accInfo.conversationModel->removeConversationMember(convUid, memberUri);
}

void
MessagesAdapter::removeContact(const QString& convUid, bool banContact)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();

    // remove the uri from the default moderators list
    // TODO: seems like this should be done in libringclient
    QStringList list = lrcInstance_->accountModel().getDefaultModerators(accInfo.id);
    const auto contactUri = accInfo.conversationModel->peersForConversation(convUid).at(0);
    if (!contactUri.isEmpty() && list.contains(contactUri)) {
        lrcInstance_->accountModel().setDefaultModerator(accInfo.id, contactUri, false);
    }

    // actually remove the contact
    accInfo.contactModel->removeContact(contactUri, banContact);
}

void
MessagesAdapter::onPreviewInfoReady(QString messageId, QVariantMap info)
{
    const QString& convId = lrcInstance_->get_selectedConvUid();
    const QString& accId = lrcInstance_->get_currentAccountId();
    auto& conversation = lrcInstance_->getConversationFromConvUid(convId, accId);
    conversation.interactions->addHyperlinkInfo(messageId, info);
}

void
MessagesAdapter::onConversationMessagesLoaded(uint32_t, const QString& convId)
{
    if (convId != lrcInstance_->get_selectedConvUid())
        return;
    Q_EMIT moreMessagesLoaded();
}

void
MessagesAdapter::parseMessageUrls(const QString& messageId, const QString& msg, bool showPreview)
{
    previewEngine_->parseMessage(messageId, msg, showPreview);
}

void
MessagesAdapter::onMessageLinkified(const QString& messageId, const QString& linkified)
{
    const QString& convId = lrcInstance_->get_selectedConvUid();
    const QString& accId = lrcInstance_->get_currentAccountId();
    auto& conversation = lrcInstance_->getConversationFromConvUid(convId, accId);
    conversation.interactions->linkifyMessage(messageId, linkified);
}

void
MessagesAdapter::onComposingStatusChanged(const QString& convId,
                                          const QString& contactUri,
                                          bool isComposing)
{
    Q_UNUSED(contactUri)
    if (lrcInstance_->get_selectedConvUid() == convId) {
        const QString& accId = lrcInstance_->get_currentAccountId();
        auto& conversation = lrcInstance_->getConversationFromConvUid(convId, accId);
        set_currentConvComposingList(conversationTypersUrlToName(conversation.typers));
    }
}

void
MessagesAdapter::onMessagesFoundProcessed(const QString& accountId,
                                          const VectorMapStringString& messageIds,
                                          const QVector<interaction::Info>& messageInformations)
{
    if (lrcInstance_->get_currentAccountId() != accountId) {
        return;
    }
    bool isSearchInProgress = messageIds.length();
    if (isSearchInProgress) {
        int index = -1;
        Q_FOREACH (const MapStringString& msg, messageIds) {
            index++;
            try {
                std::pair<QString, interaction::Info> message(msg["id"],
                                                              messageInformations.at(index));
                mediaInteractions_->insert(message);
            } catch (...) {
                qWarning() << "error in onMessagesFoundProcessed, message insertion on index: "
                           << index;
            }
        }
    } else {
        set_mediaMessageListModel(QVariant::fromValue(mediaInteractions_.get()));
    }
}

QList<QString>
MessagesAdapter::conversationTypersUrlToName(const QSet<QString>& typersSet)
{
    QList<QString> nameList;
    for (const auto& id : typersSet) {
        auto name = lrcInstance_->getCurrentContactModel()->bestNameForContact(id);
        nameList.append(name);
    }

    return nameList;
}

QVariantMap
MessagesAdapter::isLocalImage(const QString& mimename)
{
    if (mimename.startsWith("image/")) {
        QString fileFormat = mimename;
        fileFormat.replace("image/", "");
        QImageReader reader;
        QList<QByteArray> supportedFormats = reader.supportedImageFormats();
        auto iterator = std::find_if(supportedFormats.begin(),
                                     supportedFormats.end(),
                                     [fileFormat](QByteArray format) {
                                         return format == fileFormat;
                                     });
        return {{"isImage", iterator != supportedFormats.end()}};
    }
    return {{"isImage", false}};
}

QVariantMap
MessagesAdapter::getMediaInfo(const QString& msg)
{
    auto filePath = QFileInfo(msg).absoluteFilePath();
    static const QString html
        = "<body style='margin:0;padding:0;'>"
          "<%1 style='width:100%;height:%2;outline:none;background-color:#f1f3f4;"
          "object-fit:cover;' "
          "controls controlsList='nodownload' src='file://%3' type='%4'/></body>";
    QMimeDatabase db;
    QMimeType mime = db.mimeTypeForFile(filePath);
    QVariantMap fileInfo = isLocalImage(mime.name());
    if (fileInfo["isImage"].toBool() || fileInfo["isAnimatedImage"].toBool()) {
        return fileInfo;
    }
    static const QRegExp vPattern("(video/)(avi|mov|webm|webp|rmvb)$", Qt::CaseInsensitive);
    auto match = vPattern.indexIn(mime.name());
    QString type = vPattern.capturedTexts().size() == 3 ? vPattern.capturedTexts()[1] : "";
    if (!type.isEmpty()) {
        return {
            {"isVideo", true},
            {"html", html.arg("video", "100%", filePath, mime.name())},
        };
    } else {
        static const QRegExp aPattern("(audio/)(ogg|flac|wav|mpeg|mp3)$", Qt::CaseInsensitive);
        match = aPattern.indexIn(mime.name());
        type = aPattern.capturedTexts().size() == 3 ? aPattern.capturedTexts()[1] : "";
        if (!type.isEmpty()) {
            return {
                {"isVideo", false},
                {"html", html.arg("audio", "54px", filePath, mime.name())},
            };
        }
    }
    return {};
}

bool
MessagesAdapter::isRemoteImage(const QString& msg)
{
    // TODO: test if all these open in the AnimatedImage component
    QRegularExpression pattern("[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|apng|webp|avif|flif)$",
                               QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch match = pattern.match(msg);
    return match.hasMatch();
}

QString
MessagesAdapter::getFormattedTime(const quint64 timestamp)
{
    const auto now = QDateTime::currentDateTime();
    const auto seconds = now.toSecsSinceEpoch() - timestamp;
    auto interval = qFloor(seconds / 60);

    if (interval > 1) {
        auto curLang = settingsManager_->getValue(Settings::Key::LANG);
        auto curLocal(QLocale(curLang.toString()));
        auto curTime = QDateTime::fromSecsSinceEpoch(timestamp).time();
        QString timeLocale;
        if (curLang == "SYSTEM")
            timeLocale = QLocale::system().toString(curTime, QLocale::system().ShortFormat);
        else
            timeLocale = curLocal.toString(curTime, curLocal.ShortFormat);

        return timeLocale;
    }
    return QObject::tr("just now");
}

QString
MessagesAdapter::getFormattedDay(const quint64 timestamp)
{
    auto now = QDate::currentDate();
    auto before = QDateTime::fromSecsSinceEpoch(timestamp).date();
    if (before == now)
        return QObject::tr("Today");
    if (before.daysTo(now) == 1)
        return QObject::tr("Yesterday");

    auto curLang = settingsManager_->getValue(Settings::Key::LANG);
    auto curLocal(QLocale(curLang.toString()));
    auto curDate = QDateTime::fromSecsSinceEpoch(timestamp).date();
    QString dateLocale;
    if (curLang == "SYSTEM")
        dateLocale = QLocale::system().toString(curDate, QLocale::system().ShortFormat);
    else
        dateLocale = curLocal.toString(curDate, curLocal.ShortFormat);

    return dateLocale;
}

void
MessagesAdapter::getConvMedias()
{
    auto accountId = lrcInstance_->get_currentAccountId();
    auto convId = lrcInstance_->get_selectedConvUid();

    mediaInteractions_.reset(new MessageListModel(this));

    try {
        lrcInstance_->getCurrentConversationModel()->getConvMediasInfos(accountId, convId);
    } catch (...) {
        qDebug() << "Exception during getConvMedia:";
    }
}

int
MessagesAdapter::findPositionToUpdate(QVariantMap newPosition, QList<QVariantMap>& list)
{
    for (int i = 0; i < list.length(); i++) {
        if (list.at(i)["author"] == newPosition["author"]) {
            return i;
        }
    }
    return -1;
}

QString
MessagesAdapter::getAvatar(const QString& uri)
{
    QString avatarBase64;
    QByteArray ba;
    QBuffer bu(&ba);

    auto accountId = lrcInstance_->get_currentAccountId();
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    auto currentAccountUri = accInfo.profileInfo.uri;
    if (currentAccountUri == uri) {
        // use accountPhoto
        Utils::accountPhoto(lrcInstance_, accountId).save(&bu, "PNG");
    } else {
        // use contactPhoto
        Utils::contactPhoto(lrcInstance_, uri).save(&bu, "PNG");
    }
    return ba.toBase64();
}
QVariantMap
MessagesAdapter::parseJsonPosition(const QString& body, const QString& peerId)
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

        pos["author"] = peerId;
    }
    return pos;
}

void
MessagesAdapter::onPositionReceived(const QString& peerId,
                                    const QString& body,
                                    const uint64_t& timestamp,
                                    const QString& daemonId)
{
    QVariantMap newPosition = parseJsonPosition(body, peerId);

    int indexPosition = findPositionToUpdate(newPosition, positionList_);

    int indexAvatar = findPositionToUpdate(newPosition, avatarPositionList_);

    // existing position to update
    if (indexPosition >= 0) {
        if (newPosition["type"] == "Stop") {
            positionList_.remove(indexPosition);
            if (indexAvatar >= 0) {
                avatarPositionList_.remove(indexAvatar);
                qWarning() << "remove avatar: length = " << avatarPositionList_.length();
            }
        } else {
            positionList_.at(indexPosition)["long"] = newPosition["long"];
            positionList_.at(indexPosition)["lat"] = newPosition["lat"];
            positionList_.at(indexPosition)["author"] = peerId;
        }
        // new shared position
    } else {
        positionList_.append(newPosition);
        QVariantMap avatarMap;
        avatarMap["author"] = peerId;
        avatarMap["avatar"] = getAvatar(peerId);
        avatarPositionList_.append(avatarMap);
        Q_EMIT avatarPositionListChanged();
    }
    Q_EMIT positionListChanged();
}
