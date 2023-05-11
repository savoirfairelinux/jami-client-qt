/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
#include "previewengine.h"

#include <QObject>
#include <QString>
#include <QTimer>

#include <QSortFilterProxyModel>

class AppSettingsManager;
class MessageParser;

class FilteredMsgListModel final : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    explicit FilteredMsgListModel(QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        sort(0, Qt::AscendingOrder);
    }
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        auto type = static_cast<interaction::Type>(
            sourceModel()->data(index, MessageList::Role::Type).toInt());
        return interaction::isDisplayedInChatview(type);
    };
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override
    {
        return left.row() > right.row();
    };
};

class MessagesAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_RO_PROPERTY(QVariant, messageListModel)
    QML_PROPERTY(QString, replyToId)
    QML_PROPERTY(QString, editId)
    QML_RO_PROPERTY(QList<QString>, currentConvComposingList)
    QML_PROPERTY(QVariant, mediaMessageListModel)
    QML_PROPERTY(QString, searchbarPrompt)

public:
    explicit MessagesAdapter(AppSettingsManager* settingsManager,
                             PreviewEngine* previewEngine,
                             LRCInstance* instance,
                             QObject* parent = nullptr);
    ~MessagesAdapter() = default;

Q_SIGNALS:
    void newInteraction(const QString& id, int type);
    void newMessageBarPlaceholderText(QString& placeholderText);
    void newFilePasted(QString filePath);
    void newTextPasted();
    void previewInformationToQML(QString messageId, QStringList previewInformation);
    void moreMessagesLoaded(qint32 loadingRequestId);
    void timestampUpdated();

protected:
    Q_INVOKABLE bool isDocument(const interaction::Type& type);
    Q_INVOKABLE void loadMoreMessages();
    Q_INVOKABLE qint32 loadConversationUntil(const QString& to);
    Q_INVOKABLE void connectConversationModel();
    Q_INVOKABLE void sendConversationRequest();
    Q_INVOKABLE void removeConversation(const QString& convUid);
    Q_INVOKABLE void addConversationMember(const QString& convUid, const QString& participantUri);
    Q_INVOKABLE void removeConversationMember(const QString& convUid, const QString& participantUri);
    Q_INVOKABLE void removeContact(const QString& convUid, bool banContact = false);
    Q_INVOKABLE void clearConversationHistory(const QString& accountId, const QString& convUid);
    Q_INVOKABLE void acceptInvitation(const QString& convId = {});
    Q_INVOKABLE void refuseInvitation(const QString& convUid = "");
    Q_INVOKABLE void blockConversation(const QString& convUid = "");
    Q_INVOKABLE void unbanContact(int index);
    Q_INVOKABLE void unbanConversation(const QString& convUid);
    Q_INVOKABLE void sendMessage(const QString& message);
    Q_INVOKABLE void editMessage(const QString& convId,
                                 const QString& newBody,
                                 const QString& messageId = "");
    Q_INVOKABLE void addEmojiReaction(const QString& convId,
                                      const QString& emoji,
                                      const QString& messageId = "");
    Q_INVOKABLE void removeEmojiReaction(const QString& convId,
                                         const QString& emoji,
                                         const QString& messageId);
    Q_INVOKABLE void sendFile(const QString& message);
    Q_INVOKABLE void acceptFile(const QString& arg);
    Q_INVOKABLE void cancelFile(const QString& arg);
    Q_INVOKABLE void openUrl(const QString& url);
    Q_INVOKABLE void openDirectory(const QString& arg);
    Q_INVOKABLE void deleteInteraction(const QString& interactionId);
    Q_INVOKABLE void joinCall(const QString& uri,
                              const QString& deviceId,
                              const QString& confId,
                              bool isAudioOnly = false);
    Q_INVOKABLE void copyToDownloads(const QString& interactionId, const QString& displayName);
    Q_INVOKABLE void userIsComposing(bool isComposing);
    Q_INVOKABLE QVariantMap isLocalImage(const QString& mimeName);
    Q_INVOKABLE QVariantMap getMediaInfo(const QString& msg);
    Q_INVOKABLE bool isRemoteImage(const QString& msg);
    Q_INVOKABLE QString getFormattedDay(const quint64 timestamp);
    Q_INVOKABLE QString getFormattedTime(const quint64 timestamp);
    Q_INVOKABLE QString getBestFormattedDate(const quint64 timestamp);
    Q_INVOKABLE void parseMessage(const QString& msgId,
                                  const QString& msg,
                                  bool previewLinks,
                                  const QColor& linkColor = QColor(0x06, 0x45, 0xad));
    Q_INVOKABLE void onPaste();
    Q_INVOKABLE int getIndexOfMessage(const QString& messageId) const;
    Q_INVOKABLE QString getStatusString(int status);
    Q_INVOKABLE QVariantMap getTransferStats(const QString& messageId, int);
    Q_INVOKABLE QVariant dataForInteraction(const QString& interactionId,
                                            int role = Qt::DisplayRole) const;
    Q_INVOKABLE void startSearch(const QString& text, bool isMedia);
    Q_INVOKABLE int getMessageIndexFromId(QString& id);

    // Run corrsponding js functions, c++ to qml.
    void setMessagesImageContent(const QString& path, bool isBased64 = false);
    void setMessagesFileContent(const QString& path);
    void setSendMessageContent(const QString& content);

    inline MessageListModel* getMsgListSourceModel() const;

private Q_SLOTS:
    void onNewInteraction(const QString& convUid,
                          const QString& interactionId,
                          const interaction::Info& interaction);
    void onMessageParsed(const QString& messageId, const QString& parsed);
    void onLinkInfoReady(QString messageIndex, QVariantMap urlInMessage);
    void onConversationMessagesLoaded(uint32_t requestId, const QString& convId);
    void onComposingStatusChanged(const QString& convId,
                                  const QString& contactUri,
                                  bool isComposing);
    void onMessagesFoundProcessed(const QString& accountId,
                                  const QMap<QString, interaction::Info>& messageInformation);

private:
    QList<QString> conversationTypersUrlToName(const QSet<QString>& typersSet);

    AppSettingsManager* settingsManager_;
    MessageParser* messageParser_;

    FilteredMsgListModel* filteredMsgListModel_;

    static constexpr const int loadChunkSize_ {20};

    std::unique_ptr<MessageListModel> mediaInteractions_;

    QTimer* timestampTimer_ {nullptr};
    static constexpr const int timestampUpdateIntervalMs_ {1000};
};
