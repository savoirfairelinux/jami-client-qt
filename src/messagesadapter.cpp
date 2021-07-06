/*!
 * Copyright (C) 2020 by Savoir-faire Linux
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
#include "utils.h"

#include <regex>

#include <api/datatransfermodel.h>

#include <QApplication>
#include <QClipboard>
#include <QDesktopServices>
#include <QFileInfo>
#include <QImageReader>
#include <QList>
#include <QUrl>
#include <QMimeData>
#include <QBuffer>

MessagesAdapter::MessagesAdapter(AppSettingsManager* settingsManager,
                                 LRCInstance* instance,
                                 QObject* parent)
    : QmlAdapterBase(instance, parent)
    , settingsManager_(settingsManager)
    , previewEngine_(new PreviewEngine(this))
{
    connect(lrcInstance_, &LRCInstance::selectedConvUidChanged, [this]() {
        const QString& convId = lrcInstance_->get_selectedConvUid();
        auto& conversation
            = lrcInstance_->getConversationFromConvUid(convId, lrcInstance_->get_currentAccountId());
        QVariant v;
        v.setValue(&(*(conversation.interactions)));
        set_messageListModel(v);
    });

    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessagesAdapter::onPreviewInfoReady);
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
    auto optConv = convModel->getConversationForUid(lrcInstance_->get_selectedConvUid());
    if (!optConv)
        return;

    loadMessages(optConv->get());

    // TODO: current conv observe
    Q_EMIT newMessageBarPlaceholderText(convInfo["title"].toString());
}

void
MessagesAdapter::loadMessages(const conversation::Info& convInfo)
{
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    qDebug() << convInfo.allMessagesLoaded;
    if (convInfo.isSwarm() && !convInfo.allMessagesLoaded) {
        qDebug() << "LOAD MORE MESSAGES";

        convModel->loadConversationMessages(convInfo.uid, 20);
    }
}

void
MessagesAdapter::onNewInteraction(const QString& convUid,
                                  const QString& interactionId,
                                  const interaction::Info& interaction)
{
    auto accountId = lrcInstance_->get_currentAccountId();
    newInteraction(accountId, convUid, interactionId, interaction);
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
                     &ConversationModel::newMessagesAvailable,
                     this,
                     &MessagesAdapter::onNewMessagesAvailable,
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
        lrcInstance_->getCurrentConversationModel()->sendMessage(convUid, message);
    } catch (...) {
        qDebug() << "Exception during sendMessage:" << message;
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
MessagesAdapter::openFile(const QString& arg)
{
    QUrl fileUrl("file:///" + arg);
    if (!QDesktopServices::openUrl(fileUrl)) {
        qDebug() << "Couldn't open file: " << fileUrl;
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
MessagesAdapter::acceptFile(const QString& interactionId)
{
    auto convUid = lrcInstance_->get_selectedConvUid();
    lrcInstance_->getCurrentConversationModel()->acceptTransfer(convUid, interactionId);
}

void
MessagesAdapter::refuseFile(const QString& interactionId)
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
        QString fileName = "\\img_" + QString(img_name_hash.toHex()) + ".png";
        QString path = QString(Utils::WinGetEnv("TEMP")) + fileName;

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
            QString filePath = urlList.at(i).toString().remove(QRegExp("^file:\\/{2,3}"));
            Q_EMIT newFilePasted(filePath);
        }
    } else {
        // Treat as text content, make chatview.js handle in order to
        // avoid string escape problems
        Q_EMIT newTextPasted();
    }
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
MessagesAdapter::newInteraction(const QString& accountId,
                                const QString& convUid,
                                const QString& interactionId,
                                const interaction::Info& interaction)
{
    Q_UNUSED(interactionId);
    try {
        if (convUid.isEmpty() || convUid != lrcInstance_->get_selectedConvUid()) {
            return;
        }
        auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
        auto& convModel = accountInfo.conversationModel;
        convModel->clearUnreadInteractions(convUid);
        Q_EMIT newInteraction(static_cast<int>(interaction.type));
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
MessagesAdapter::clearConversationHistory(const QString& accountId, const QString& convUid)
{
    lrcInstance_->getAccountInfo(accountId).conversationModel->clearHistory(convUid);
}

void
MessagesAdapter::removeConversation(const QString& accountId,
                                    const QString& convUid,
                                    bool banContact)
{
    QStringList list = lrcInstance_->accountModel().getDefaultModerators(accountId);
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    const auto contactURI = convInfo.participants.front();

    if (!contactURI.isEmpty() && list.contains(contactURI)) {
        lrcInstance_->accountModel().setDefaultModerator(accountId, contactURI, false);
    }

    lrcInstance_->getAccountInfo(accountId).conversationModel->removeConversation(convUid,
                                                                                  banContact);
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
MessagesAdapter::onNewMessagesAvailable(const QString& accountId, const QString& conversationId)
{
    // TODO: implement this slot
}

void
MessagesAdapter::beginBuildPreview(QString messageId, QString url)
{
    previewEngine_->getPreviewInfo(messageId, url);
}

void
MessagesAdapter::loadMoreMessages()
{

    const QString& convId = lrcInstance_->get_selectedConvUid();
    auto& conversation
        = lrcInstance_->getConversationFromConvUid(convId, lrcInstance_->get_currentAccountId());

    loadMessages(conversation);
}
