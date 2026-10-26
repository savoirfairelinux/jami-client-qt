/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
#include "messageparser.h"
#include "appsettingsmanager.h"

#include <QObject>
#include <QString>
#include <QTimer>

#include "threadedmsglistmodel.h"

#include <QSortFilterProxyModel>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class FilteredMsgListModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    explicit FilteredMsgListModel(QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        sort(0, Qt::AscendingOrder);

        connect(this, &QAbstractItemModel::rowsInserted, this, &FilteredMsgListModel::countChanged);
        connect(this, &QAbstractItemModel::rowsRemoved, this, &FilteredMsgListModel::countChanged);
        connect(this, &QAbstractItemModel::modelReset, this, &FilteredMsgListModel::countChanged);
        connect(this, &QAbstractItemModel::layoutChanged, this, &FilteredMsgListModel::countChanged);
    }
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        auto type = static_cast<interaction::Type>(sourceModel()->data(index, MessageList::Role::Type).toInt());
        return interaction::isTypeDisplayable(type);
    };
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override
    {
        return left.row() > right.row();
    };

    Q_INVOKABLE int getDisplayIndex(const QString& id)
    {
        auto sourceRow = ((MessageListModel*) sourceModel())->indexOfMessage(id);
        auto index = mapFromSource(sourceModel()->index(sourceRow, 0));
        return index.row();
    };
    Q_INVOKABLE QVariantMap get(int row) const
    {
        QVariantMap map;
        QModelIndex modelIndex = index(row, 0);
        QHash<int, QByteArray> roles = roleNames();
        for (QHash<int, QByteArray>::const_iterator it = roles.begin(); it != roles.end(); ++it)
            map.insert(it.value(), data(modelIndex, it.key()));
        return map;
    }

    int count() const
    {
        return rowCount();
    }
Q_SIGNALS:
    void countChanged();
};

// The one history request allowed in flight for the selected conversation.
struct HistoryRequest
{
    enum Result { Ignored, Progress, NoProgress };

    // requestId is ConversationModel::loadConversationMessages()'s result: -1 when all is loaded, 0 on failure.
    bool start(const QString& accountId, const QString& convId, int requestId, int rowCount)
    {
        if (pending() || requestId == 0 || requestId == -1)
            return false;
        accountId_ = accountId;
        convId_ = convId;
        id_ = static_cast<uint32_t>(requestId);
        rowCount_ = rowCount;
        return true;
    }
    Result finish(const QString& accountId, const QString& convId, uint32_t requestId, int rowCount)
    {
        if (!pending() || requestId != id_ || convId != convId_ || accountId != accountId_)
            return Ignored;
        id_ = 0;
        return rowCount > rowCount_ ? Progress : NoProgress;
    }
    void reset()
    {
        id_ = 0;
    }
    bool pending() const
    {
        return id_ != 0;
    }

private:
    QString accountId_;
    QString convId_;
    uint32_t id_ {0};
    int rowCount_ {0};
};

class MessagesAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

    QML_RO_PROPERTY(QVariant, messageListModel)
    // Thread roots for the main message list, and the thread shown in the thread panel.
    QML_RO_PROPERTY(QVariant, threadedMessageListModel)
    QML_RO_PROPERTY(QVariant, threadMessageListModel)
    QML_RO_PROPERTY(bool, historyStalled)
    // A jump target being paged in for the threaded view, and whether the last one was not found.
    QML_RO_PROPERTY(QString, navigationTarget)
    QML_RO_PROPERTY(bool, navigationFailed)
    Q_PROPERTY(bool threadedView READ threadedView WRITE setThreadedView NOTIFY threadedViewChanged)
    QML_PROPERTY(QString, replyToId)
    QML_PROPERTY(QString, editId)
    QML_RO_PROPERTY(QList<QString>, currentConvComposingList)
    QML_PROPERTY(QVariant, mediaMessageListModel)
    QML_PROPERTY(QString, searchbarPrompt)

public:
    static MessagesAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new MessagesAdapter(qApp->property("AppSettingsManager").value<AppSettingsManager*>(),
                                   qApp->property("PreviewEngine").value<PreviewEngine*>(),
                                   qApp->property("LRCInstance").value<LRCInstance*>());
    }

    explicit MessagesAdapter(AppSettingsManager* settingsManager,
                             PreviewEngine* previewEngine,
                             LRCInstance* instance,
                             QObject* parent = nullptr);
    ~MessagesAdapter() = default;

    bool threadedView() const;
    void setThreadedView(bool enabled);
    // For the thread panel's composer (inThread) or the main one; only for the selected conversation.
    // The explicit reply is used by the composer whose list shows it, else the thread composer replies to its root.
    Q_INVOKABLE QString replyTargetFor(const QString& convUid, bool inThread = false) const;
    // Whether id is in the thread open in the thread panel.
    Q_INVOKABLE bool inOpenThread(const QString& id) const;
    // Opens a loaded reply's thread; pages in an unloaded target. Returns whether it is loaded.
    Q_INVOKABLE bool revealMessage(const QString& id);
    Q_INVOKABLE void cancelNavigation();

    Q_INVOKABLE bool isDocument(const interaction::Type& type);
    Q_INVOKABLE void loadMoreMessages();
    Q_INVOKABLE void connectConversationModel();
    Q_INVOKABLE void sendConversationRequest();
    Q_INVOKABLE void removeConversation(const QString& convUid, bool keepContact = false);
    Q_INVOKABLE void addConversationMember(const QString& convUid, const QString& participantUri);
    Q_INVOKABLE void removeConversationMember(const QString& convUid, const QString& participantUri);
    Q_INVOKABLE void removeContact(const QString& convUid, bool banContact = false);
    Q_INVOKABLE void clearConversationHistory(const QString& accountId, const QString& convUid);
    Q_INVOKABLE void acceptInvitation(const QString& convId = {});
    Q_INVOKABLE void declineInvitation(const QString& convUid = "");
    Q_INVOKABLE void blockConversation(const QString& convUid = "");
    Q_INVOKABLE void unbanContact(int index);
    Q_INVOKABLE void unbanConversation(const QString& convUid);
    Q_INVOKABLE void sendMessage(const QString& message);
    Q_INVOKABLE void sendMessageToUid(const QString& message, const QString& convUid, bool inThread = false);
    Q_INVOKABLE void editMessage(const QString& convId, const QString& newBody, const QString& messageId = "");
    Q_INVOKABLE void addEmojiReaction(const QString& convId, const QString& emoji, const QString& messageId = "");
    Q_INVOKABLE void removeEmojiReaction(const QString& convId, const QString& emoji, const QString& messageId);
    Q_INVOKABLE void removeReaction(const QString& convId, const QString& reactionId);
    Q_INVOKABLE void sendFile(const QString& message, bool inThread = false);
    Q_INVOKABLE void sendFileToUid(const QString& message, const QString& convUid);
    Q_INVOKABLE void acceptFile(const QString& arg);
    Q_INVOKABLE void cancelFile(const QString& arg);
    Q_INVOKABLE void openUrl(const QString& url);
    Q_INVOKABLE void openDirectory(const QString& arg);
    Q_INVOKABLE void removeFile(const QString& interactionId, const QString& path);
    Q_INVOKABLE void joinCall(const QString& uri,
                              const QString& deviceId,
                              const QString& confId,
                              bool videoMuted = true);
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
                                  const QColor& linkColor = QColor(0x06, 0x45, 0xad),
                                  const QColor& backgroundColor = QColor(0x0, 0x0, 0x0));
    Q_INVOKABLE void parseOriginalMessage(const QString& msgId,
                                          const QString& msg,
                                          const QColor& linkColor = QColor(0x06, 0x45, 0xad),
                                          const QColor& backgroundColor = QColor(0x0, 0x0, 0x0));
    Q_INVOKABLE void onPaste();
    Q_INVOKABLE QVariantMap getTransferStats(const QString& messageId, int);
    Q_INVOKABLE QVariant dataForInteraction(const QString& interactionId, int role = Qt::DisplayRole) const;
    Q_INVOKABLE void startSearch(const QString& text, bool isMedia);

    // Run corrsponding js functions, c++ to qml.
    void setMessagesImageContent(const QString& path, bool isBased64 = false);
    void setMessagesFileContent(const QString& path);
    void setSendMessageContent(const QString& content);

    inline MessageListModel* getMsgListSourceModel() const;

Q_SIGNALS:
    void navigationTargetLoaded(const QString& id);
    void newInteraction(const QString& id, int type);
    void newFilePasted(const QString& filePath);
    void newTextPasted();
    void moreMessagesLoaded(qint32 loadingRequestId);
    void threadedViewChanged();
    void timestampUpdated();
    void fileCopied(const QString& fileName, const QString& downloadDir);
    void messageParsed(const QString& msgId, const QString& msg);

private Q_SLOTS:
    void onNewInteraction(const QString& convUid, const QString& interactionId, const interaction::Info& interaction);
    void onMessageParsed(const QString& messageId, const QString& parsed);
    void onOriginalMessageParsed(const QString& messageId, const QString& parsed);
    void onLinkInfoReady(const QString& messageIndex, const QVariantMap& info);
    void onConversationMessagesLoaded(uint32_t requestId, const QString& convId);
    void onComposingStatusChanged(const QString& convId, const QString& contactUri, bool isComposing);
    void onMessagesFoundProcessed(const QString& accountId, const QMap<QString, interaction::Info>& messageInformation);

private:
    QList<QString> conversationTypersUrlToName(const QSet<QString>& typersSet);
    void onSelectedConversationChanged();
    void continueNavigation();

    AppSettingsManager* settingsManager_;
    MessageParser* messageParser_;
    FilteredMsgListModel* filteredMsgListModel_;
    ThreadedMsgListModel* threadedMsgListModel_;
    ThreadedMsgListModel* threadMsgListModel_;
    HistoryRequest historyRequest_;
    std::unique_ptr<MessageListModel> mediaInteractions_;
    QTimer* timestampTimer_;
    static constexpr const int loadChunkSize_ {20};
    static constexpr const int timestampUpdateIntervalMs_ {1000};
    QLocale curLocale_;
    QString dateFormatCurrentYear_;
    QString dateFormatOtherYears_;

    void updateDateFormats();
};
