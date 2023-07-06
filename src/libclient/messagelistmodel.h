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

    // map functions
    QPair<iterator, bool> emplace(const QString& msgId,
                                  interaction::Info message,
                                  bool beginning = false);
    iterator find(const QString& msgId);
    iterator findActiveCall(const MapStringString& commit);
    iterator erase(const iterator& it);

    constIterator find(const QString& msgId) const;
    QPair<iterator, bool> insert(std::pair<QString, interaction::Info> message,
                                 bool beginning = false);
    Q_INVOKABLE int erase(const QString& msgId);
    interaction::Info& operator[](const QString& messageId);
    iterator end();
    constIterator end() const;
    reverseIterator rend();

    constIterator cend() const;
    iterator begin();
    constIterator begin() const;
    reverseIterator rbegin();
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

    // use these if the underlying data model is changed from conversationmodel
    // Note: this is not ideal, and this class should be refactored into a proper
    // view model and absorb the interaction management logic to avoid exposing
    // these emission wrappers
    void emitDataChanged(iterator it, VectorInt roles = {});
    void emitDataChanged(const QString& msgId, VectorInt roles = {});
    bool isOnlyEmoji(const QString& text) const;

    QVariantMap convertReactMessagetoQVariant(const QSet<QString>&);
    QString lastSelfMessageId(const QString& id) const;

protected:
    using Role = MessageList::Role;

private:
    QList<QPair<QString, interaction::Info>> interactions_;
    // Note: because read status are updated even if interaction is not loaded
    // we need to keep track of these status outside the interaction::Info
    // lastDisplayedMessageUid_ stores: {"peerId":"messageId"}
    // messageToReaders_ caches: "messageId":["peer1", "peer2"]
    // to allow quick access.
    QMap<QString, QString> lastDisplayedMessageUid_;
    QMap<QString, QStringList> messageToReaders_;
    QMap<QString, QSet<QString>> replyTo_;
    const account::Info* account_;
    void updateReplies(item_t& message);

    void insertMessage(int index, item_t& message);
    iterator insertMessage(iterator it, item_t& message);
    void removeMessage(int index, iterator it);
};
} // namespace api
} // namespace lrc
Q_DECLARE_METATYPE(lrc::api::MessageListModel*)
