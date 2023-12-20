/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
#include "messageparser.h"

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

MessagesAdapter::MessagesAdapter(AppSettingsManager* settingsManager,
                                 PreviewEngine* previewEngine,
                                 LRCInstance* instance,
                                 QObject* parent)
    : QmlAdapterBase(instance, parent)
    , settingsManager_(settingsManager)
    , messageParser_(new MessageParser(previewEngine, this))
    , filteredMsgListModel_(new FilteredMsgListModel(this))
    , mediaInteractions_(std::make_unique<MessageListModel>(nullptr))
    , timestampTimer_(new QTimer(this))
{
    setObjectName(typeid(*this).name());

    set_messageListModel(QVariant::fromValue(filteredMsgListModel_));

    connect(settingsManager_,
            &AppSettingsManager::reloadHistory,
            &lrcInstance_->accountModel(),
            &AccountModel::reloadHistory);

    connect(lrcInstance_, &LRCInstance::selectedConvUidChanged, this, [this]() {
        set_replyToId("");
        set_editId("");
        const QString& convId = lrcInstance_->get_selectedConvUid();
        const auto& conversation = lrcInstance_->getConversationFromConvUid(convId);

        // Reset the source model for the proxy model.
        filteredMsgListModel_->setSourceModel(conversation.interactions.get());

        set_currentConvComposingList(conversationTypersUrlToName(conversation.typers));
    });

    connect(messageParser_, &MessageParser::messageParsed, this, &MessagesAdapter::onMessageParsed);
    connect(messageParser_, &MessageParser::linkInfoReady, this, &MessagesAdapter::onLinkInfoReady);

    connect(timestampTimer_, &QTimer::timeout, this, &MessagesAdapter::timestampUpdated);
    timestampTimer_->start(timestampUpdateIntervalMs_);

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &MessagesAdapter::connectConversationModel);

    connectConversationModel();
}

bool
MessagesAdapter::isDocument(const interaction::Type& type)
{
    return interaction::Type::DATA_TRANSFER == type;
}

void
MessagesAdapter::loadMoreMessages()
{
    auto accountId = lrcInstance_->get_currentAccountId();
    auto convId = lrcInstance_->get_selectedConvUid();
    try {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId, accountId);
        if (convInfo.isSwarm())
            lrcInstance_->getCurrentConversationModel()->loadConversationMessages(convId,
                                                                                  loadChunkSize_);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
MessagesAdapter::connectConversationModel()
{
    auto currentConversationModel = lrcInstance_->getCurrentConversationModel();
    if (currentConversationModel == nullptr) {
        return;
    }

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

    mediaInteractions_.reset(new MessageListModel(&lrcInstance_->getCurrentAccountInfo(), this));
    set_mediaMessageListModel(QVariant::fromValue(mediaInteractions_.get()));
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
    } catch (...) {
        qDebug() << "Exception during sendMessage:" << message;
    }
}

void
MessagesAdapter::editMessage(const QString& convId, const QString& newBody, const QString& messageId)
{
    try {
        auto editId = !messageId.isEmpty() ? messageId : editId_;
        if (editId.isEmpty()) {
            return;
        }
        set_editId("");
        lrcInstance_->getCurrentConversationModel()->editMessage(convId, newBody, editId);
    } catch (...) {
        qDebug() << "Exception during message edition:" << messageId;
    }
}

void
MessagesAdapter::removeEmojiReaction(const QString& convId,
                                     const QString& emoji,
                                     const QString& messageId)
{
    try {
        // check if this emoji has already been added by this author
        editMessage(convId, "", messageId);
    } catch (...) {
        qDebug() << "Exception during removeEmojiReaction():" << messageId;
    }
}

void
MessagesAdapter::addEmojiReaction(const QString& convId,
                                  const QString& emoji,
                                  const QString& messageId)
{
    try {
        lrcInstance_->getCurrentConversationModel()->reactMessage(convId, emoji, messageId);
    } catch (...) {
        qDebug() << "Exception during addEmojiReaction():" << messageId;
    }
}

void
MessagesAdapter::sendFile(const QString& message)
{
    QFileInfo fi(message);
    QString fileName = fi.fileName();
    try {
        auto convUid = lrcInstance_->get_selectedConvUid();
        lrcInstance_->getCurrentConversationModel()->sendFile(convUid,
                                                              message,
                                                              fileName,
                                                              replyToId_);
    } catch (...) {
        qDebug() << "Exception during sendFile";
    }
}

void
MessagesAdapter::joinCall(const QString& uri,
                          const QString& deviceId,
                          const QString& confId,
                          bool isAudioOnly)
{
    lrcInstance_->getCurrentConversationModel()->joinCall(lrcInstance_->get_selectedConvUid(),
                                                          uri,
                                                          deviceId,
                                                          confId,
                                                          isAudioOnly);
}

void
MessagesAdapter::copyToDownloads(const QString& interactionId, const QString& displayName)
{
    auto downloadDir = lrcInstance_->accountModel().downloadDirectory;
    if (auto accInfo = &lrcInstance_->getCurrentAccountInfo()) {
        auto dest = accInfo->dataTransferModel->copyTo(lrcInstance_->get_currentAccountId(),
                                                       lrcInstance_->get_selectedConvUid(),
                                                       interactionId,
                                                       downloadDir,
                                                       displayName);
        if (!dest.isEmpty()) {
            Q_EMIT fileCopied(dest);
        }
    }
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
MessagesAdapter::removeFile(const QString& interactionId, const QString& path)
{
    auto convUid = lrcInstance_->get_selectedConvUid();
    lrcInstance_->getCurrentConversationModel()->removeFile(convUid, interactionId, path);
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
            const static QRegularExpression fileSchemeRe("^file:\\/{2,3}");
            QString filePath = urlList.at(i).toString().remove(fileSchemeRe);
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
    if (auto* model = getMsgListSourceModel()) {
        return model->data(interactionId, role);
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
MessagesAdapter::onMessageParsed(const QString& messageId, const QString& parsed)
{
    if (messageId.isEmpty()) {
        Q_EMIT messageParsed(messageId, parsed);
        return;
    }
    const QString& convId = lrcInstance_->get_selectedConvUid();
    const QString& accId = lrcInstance_->get_currentAccountId();
    auto& conversation = lrcInstance_->getConversationFromConvUid(convId, accId);
    conversation.interactions->setParsedMessage(messageId, parsed);
}

void
MessagesAdapter::onLinkInfoReady(const QString& messageId, const QVariantMap& info)
{
    const QString& convId = lrcInstance_->get_selectedConvUid();
    const QString& accId = lrcInstance_->get_currentAccountId();
    auto& conversation = lrcInstance_->getConversationFromConvUid(convId, accId);
    conversation.interactions->addHyperlinkInfo(messageId, info);
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
MessagesAdapter::addConversationMember(const QString& convUid, const QString& memberUri)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    accInfo.conversationModel->addConversationMember(convUid, memberUri);
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
MessagesAdapter::onConversationMessagesLoaded(uint32_t loadingRequestId, const QString& convId)
{
    if (convId != lrcInstance_->get_selectedConvUid())
        return;
    Q_EMIT moreMessagesLoaded(loadingRequestId);
}

void
MessagesAdapter::parseMessage(const QString& msgId,
                              const QString& msg,
                              bool showPreview,
                              const QColor& linkColor,
                              const QColor& backgroundColor)
{
    messageParser_->parseMessage(msgId, msg, showPreview, linkColor, backgroundColor);
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
                                          const QMap<QString, interaction::Info>& messageInformation)
{
    if (lrcInstance_->get_currentAccountId() != accountId) {
        return;
    }

    bool isSearchInProgress = messageInformation.size();
    if (isSearchInProgress) {
        for (auto it = messageInformation.begin(); it != messageInformation.end(); it++) {
            mediaInteractions_->append(it.key(), it.value());
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
        if (iterator != supportedFormats.end() && *iterator == "gif") {
            return {{"isAnimatedImage", true}};
        }
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
          "controls controlsList='nodownload noplaybackrate' src='file://%3' type='%4'/></body>";
    QMimeDatabase db;
    QMimeType mime = db.mimeTypeForFile(filePath);
    QVariantMap fileInfo = isLocalImage(mime.name());
    if (fileInfo["isImage"].toBool() || fileInfo["isAnimatedImage"].toBool()) {
        return fileInfo;
    }
    static const QRegExp vPattern("(video/)(avi|mov|webm|webp|rmvb)$", Qt::CaseInsensitive);
    vPattern.indexIn(mime.name());
    auto captured = vPattern.capturedTexts();
    QString type = captured.size() == 3 ? captured[1] : "";
    if (!type.isEmpty()) {
        return {
            {"isVideo", true},
            {"isAudio", false},
            {"html", html.arg("video", "100%", filePath, mime.name())},
        };
    } else {
        static const QRegExp aPattern("(audio/)(ogg|flac|wav|mpeg|mp3)$", Qt::CaseInsensitive);
        aPattern.indexIn(mime.name());
        captured = aPattern.capturedTexts();
        type = captured.size() == 3 ? captured[1] : "";
        if (!type.isEmpty()) {
            return {
                {"isVideo", false},
                {"isAudio", true},
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
    const static QRegularExpression
        imageRe("[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|apng|webp|avif|flif)$",
                QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch match = imageRe.match(msg);
    return match.hasMatch();
}

QString
MessagesAdapter::getFormattedTime(const quint64 timestamp)
{
    const auto currentTime = QDateTime::currentDateTime();
    const auto seconds = currentTime.toSecsSinceEpoch() - timestamp;
    auto interval = qFloor(seconds / 60);

    if (interval > 1) {
        auto curLang = settingsManager_->getLanguage();
        auto curLocal = QLocale(curLang);
        auto curTime = QDateTime::fromSecsSinceEpoch(timestamp).time();
        QString timeLocale;
        timeLocale = curLocal.toString(curTime, curLocal.ShortFormat).toLower();
        return timeLocale;
    }
    return QObject::tr("just now");
}

QString
MessagesAdapter::getBestFormattedDate(const quint64 timestamp)
{
    auto currentDate = QDate::currentDate();
    auto timestampDate = QDateTime::fromSecsSinceEpoch(timestamp).date();
    if (timestampDate == currentDate)
        return getFormattedTime(timestamp);
    return getFormattedDay(timestamp);
}

QString
MessagesAdapter::getFormattedDay(const quint64 timestamp)
{
    auto currentDate = QDate::currentDate();
    auto timestampDate = QDateTime::fromSecsSinceEpoch(timestamp).date();
    if (timestampDate == currentDate)
        return QObject::tr("Today");
    if (timestampDate.daysTo(currentDate) == 1)
        return QObject::tr("Yesterday");

    auto curLang = settingsManager_->getLanguage();
    auto curLocal = QLocale(curLang);
    auto curDate = QDateTime::fromSecsSinceEpoch(timestamp).date();
    QString dateLocale;
    dateLocale = curLocal.toString(curDate, curLocal.ShortFormat);

    return dateLocale;
}

void
MessagesAdapter::startSearch(const QString& text, bool isMedia)
{
    auto accountId = lrcInstance_->get_currentAccountId();
    mediaInteractions_.reset(new MessageListModel(&lrcInstance_->getCurrentAccountInfo(), this));
    set_mediaMessageListModel(QVariant::fromValue(mediaInteractions_.get()));

    if (text.isEmpty() && !isMedia)
        return;

    auto convId = lrcInstance_->get_selectedConvUid();

    try {
        lrcInstance_->getCurrentConversationModel()->getConvMediasInfos(accountId,
                                                                        convId,
                                                                        text,
                                                                        isMedia);
    } catch (...) {
        qDebug() << "Exception during startSearch()";
    }
}

MessageListModel*
MessagesAdapter::getMsgListSourceModel() const
{
    // We are certain that filteredMsgListModel_'s source model is a MessageListModel,
    // However it may be a nullptr if not yet set.
    return static_cast<MessageListModel*>(filteredMsgListModel_->sourceModel());
}
