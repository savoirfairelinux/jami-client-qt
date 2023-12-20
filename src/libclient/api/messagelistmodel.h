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
    // A pair of message id and interaction info.
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

    void clear();
    void reloadHistory();
    bool empty() const;
    int indexOfMessage(const QString& msgId, bool reverse = true) const;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    Q_INVOKABLE virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    Q_INVOKABLE virtual QVariant data(int idx, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const override;

    QVariant dataForItem(item_t item, int indexRow, int role = Qt::DisplayRole) const;
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

    // Thread-safe access to interactions.
    // Note: be careful when using these functions to modify the interactions as
    //       dataChanged() signal is not emitted. Use add/update/remove instead
    //       if per-message UI updates are required. Also, DO NOT use these to
    //       modify the interactions_ container.
    using InteractionCb = std::function<void(const QString&, interaction::Info&)>;
    void forEach(const InteractionCb&);
    // Operations on a single interaction. Returns true if the interaction is found.
    // Note: if idHint is an empty string, the last interaction is used.
    bool with(const QString& idHint, const InteractionCb&);
    // A convenience function to access the last interaction.
    bool withLast(const InteractionCb&);

    // Get a copy of an interaction by id. If the interaction is not found,
    // type will be interaction::Type::INVALID.
    interaction::Info get(const QString& id) const;

    QPair<QString, time_t> getDisplayedInfoForPeer(const QString& peerId);
    bool isOutgoing(const QString& id);

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
