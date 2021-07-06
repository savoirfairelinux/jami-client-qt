/*!
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
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
#include "api/chatview.h"

#include "previewengine.h"

#include <QObject>
#include <QString>

class AppSettingsManager;

class MessagesAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap chatviewTranslatedStrings MEMBER chatviewTranslatedStrings_ CONSTANT)
    QML_PROPERTY(QVariant, messageListModel)

public:
    explicit MessagesAdapter(AppSettingsManager* settingsManager,
                             LRCInstance* instance,
                             QObject* parent = nullptr);
    ~MessagesAdapter() = default;

Q_SIGNALS:
    void newInteraction(int type);
    void newMessageBarPlaceholderText(QString placeholderText);
    void newFilePasted(QString filePath);
    void newTextPasted();
    void previewInformationToQML(QString messageId, QStringList previewInformation);

protected:
    void safeInit() override;

    Q_INVOKABLE void setupChatView(const QVariantMap& convInfo);
    Q_INVOKABLE void connectConversationModel();
    Q_INVOKABLE void sendConversationRequest();
    Q_INVOKABLE void removeConversation(const QString& accountId,
                                        const QString& convUid,
                                        bool banContact = false);
    Q_INVOKABLE void clearConversationHistory(const QString& accountId, const QString& convUid);
    Q_INVOKABLE void acceptInvitation(const QString& convId = {});
    Q_INVOKABLE void refuseInvitation(const QString& convUid = "");
    Q_INVOKABLE void blockConversation(const QString& convUid = "");
    Q_INVOKABLE void sendMessage(const QString& message);
    Q_INVOKABLE void sendFile(const QString& message);
    Q_INVOKABLE void beginBuildPreview(QString messageId, QString url);
    Q_INVOKABLE void acceptFile(const QString& arg);
    Q_INVOKABLE void refuseFile(const QString& arg);
    Q_INVOKABLE void openUrl(const QString& url);
    Q_INVOKABLE void openFile(const QString& arg);
    Q_INVOKABLE void retryInteraction(const QString& interactionId);
    Q_INVOKABLE void deleteInteraction(const QString& interactionId);
    Q_INVOKABLE void copyToDownloads(const QString& interactionId, const QString& displayName);
    Q_INVOKABLE void userIsComposing(bool isComposing);

    Q_INVOKABLE void loadMoreMessages();

    // Run corrsponding js functions, c++ to qml.
    void setMessagesImageContent(const QString& path, bool isBased64 = false);
    void setMessagesFileContent(const QString& path);
    void setSendMessageContent(const QString& content);

private Q_SLOTS:
    void onNewMessagesAvailable(const QString& accountId, const QString& conversationId);
    void onNewInteraction(const QString& convUid,
                          const QString& interactionId,
                          const interaction::Info& interaction);
    void onPreviewInfoReady(QString messageIndex, QVariantMap urlInMessage);

private:
    void setConversationProfileData(const lrc::api::conversation::Info& convInfo);
    void newInteraction(const QString& accountId,
                        const QString& convUid,
                        const QString& interactionId,
                        const interaction::Info& interaction);
    void onPaste();

    const QVariantMap chatviewTranslatedStrings_ {lrc::api::chatview::getTranslatedStrings()};

    AppSettingsManager* settingsManager_;

    PreviewEngine* previewEngine_;
    void loadMessages(const conversation::Info& convInfo);
};
