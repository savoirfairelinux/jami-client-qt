/*
 *  Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 *
 *  Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
 *  Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */
#pragma once

#include "api/interaction.h"
#include "api/account.h"
#include "database.h"

#include <QAbstractListModel>

#include <mutex>

namespace lrc {
namespace api {

namespace interaction {
struct Info;
}

#define MSG_ROLES \
    X(Id) \
    X(Author) \
    X(Body) \
    X(ParentId) \
    X(Timestamp) \
    X(Duration) \
    X(Type) \
    X(Status) \
    X(IsRead) \
    X(ContactAction) \
    X(ActionUri) \
    X(ConfId) \
    X(DeviceId) \
    X(LinkPreviewInfo) \
    X(ParsedBody) \
    X(PreviousBodies) \
    X(Reactions) \
    X(ReplyTo) \
    X(ReplyToBody) \
    X(ReplyToAuthor) \
    X(TotalSize) \
    X(TransferName) \
    X(FileExtension) \
    X(Readers) \
    X(IsEmojiOnly)

namespace MessageList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    MSG_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace MessageList

class MessageListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    using item_t = const QPair<QString, interaction::Info>;

    typedef QList<QPair<QString, interaction::Info>>::ConstIterator constIterator;
    typedef QList<QPair<QString, interaction::Info>>::Iterator iterator;
    typedef QList<QPair<QString, interaction::Info>>::reverse_iterator reverseIterator;

    explicit MessageListModel(const account::Info* account, QObject* parent = nullptr);
    ~MessageListModel() = default;

    // TODO: remove these
    iterator find(const QString& msgId);
    iterator findActiveCall(const MapStringString& commit);
    iterator erase(const iterator& it);
    constIterator find(const QString& msgId) const;
    Q_INVOKABLE int erase(const QString& msgId);

    Q_INVOKABLE int size() const;

    void clear();
    void reloadHistory();
    bool empty() const;
    interaction::Info at(const QString& intId) const;
    QPair<QString, interaction::Info> front() const;
    QPair<QString, interaction::Info> last() const;
    QPair<QString, interaction::Info> atIndex(int index) const;

    QPair<iterator, bool> insert(int index, QPair<QString, interaction::Info> message);
    int indexOfMessage(const QString& msgId, bool reverse = true) const;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    Q_INVOKABLE virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    Q_INVOKABLE virtual QVariant data(int idx, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const override;

    QVariant dataForItem(item_t item, int indexRow, int role = Qt::DisplayRole) const;
    bool contains(const QString& msgId);
    int getIndexOfMessage(const QString& messageId) const;
    void addHyperlinkInfo(const QString& messageId, const QVariantMap& info);
    void addReaction(const QString& messageId, const MapStringString& reaction);
    void rmReaction(const QString& messageId, const QString& reactionId);
    void setParsedMessage(const QString& messageId, const QString& parsed);

    void setRead(const QString& peer, const QString& messageId);
    QString getRead(const QString& peer);

    bool isOnlyEmoji(const QString& text) const;

    QVariantMap convertReactMessagetoQVariant(const QSet<QString>&);
    QString lastSelfMessageId(const QString& id) const;

    // ------------- NEW -------------
    bool insert(const QString& id, const interaction::Info& interaction, int index = -1);
    bool append(const QString& id, const interaction::Info& interaction);
    bool update(const QString& id, const interaction::Info& interaction);
    bool updateStatus(const QString& id, interaction::Status newStatus, const QString& newBody = {});
    QPair<bool, bool> addOrUpdate(const QString& id, const interaction::Info& interaction);
    void remove(const QString& id);

    using InteractionCb = std::function<void(const QString&, interaction::Info&)>;
    void forEachInteraction(const InteractionCb&);
    void resolveTransferStates(Database& db);
    QPair<bool, QString> clearUnread(Database& db);
    QString getLatestId();
    time_t getLatestTimestamp();
    QPair<QString, time_t> getDisplayedInfoForPeer(const QString& peerId);
    bool isOutgoing(const QString& id);
    bool with(const QString& id, const InteractionCb&);

    // Used when sorting conversations by timestamp, where locking multiple
    // interactions simultaneously is required.
    std::recursive_mutex& getMutex();

protected:
    using Role = MessageList::Role;

private:
    QList<QPair<QString, interaction::Info>> interactions_;

    // Note: because read status are updated even if interaction is not loaded
    // we need to keep track of these status outside the interaction::Info
    // to allow quick access.
    // lastDisplayedMessageUid_ is used to keep track of the last message displayed
    // for each peer. This is used to update the far end read status of the interaction.
    // messageToReaders_ is used to keep track of the readers of each message.
    // This is a different view of the above map, and is used to update the read
    // status of the interaction.
    QMap<QString, QString> lastDisplayedMessageUid_; // {"peerId": "messageId"}
    QMap<QString, QStringList> messageToReaders_;    // {"messageId": ["peer1", "peer2"]}

    QMap<QString, QSet<QString>> replyTo_;

    const account::Info* account_;
    void updateReplies(item_t& message);

    void insertMessage(int index, item_t& message);
    iterator insertMessage(iterator it, item_t& message);
    void removeMessage(int index, iterator it);

    // ------------- NEW -------------
    int move(iterator it, const QString& newParentId);

    mutable std::recursive_mutex mutex_;
};
} // namespace api
} // namespace lrc
Q_DECLARE_METATYPE(lrc::api::MessageListModel*)
