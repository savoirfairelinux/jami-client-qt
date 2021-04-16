/*
 * Copyright (C) 2020-2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#pragma once

#include "abstractlistmodelbase.h"

// TODO: many of these roles should probably be factored out
#define CONV_ROLES \
    X(DisplayName) \
    X(DisplayID) \
    X(Presence) \
    X(URI) \
    X(UnreadMessagesCount) \
    X(LastInteractionTimeStamp) \
    X(LastInteractionDate) \
    X(LastInteraction) \
    X(ContactType) \
    X(UID) \
    X(InCall) \
    X(IsAudioOnly) \
    X(CallStackViewShouldShow) \
    X(CallState) \
    X(AccountId) \
    X(PictureUid) \
    X(Draft)

namespace Conversation {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CONV_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace Conversation

// A generic wrapper view model around ConversationModel's underlying data
class ConversationListModelBase : public AbstractListModelBase
{
    Q_OBJECT

public:
    using item_t = OptRef<const conversation::Info>;

    explicit ConversationListModelBase(LRCInstance* instance, QObject* parent = nullptr);

    int columnCount(const QModelIndex& parent) const override;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    virtual Qt::ItemFlags flags(const QModelIndex& index) const override;
    QHash<int, QByteArray> roleNames() const override;

    virtual item_t itemFromIndex(const QModelIndex& index) const = 0;

    // Update the avatar uid map to prevent the image provider from pulling from the cache
    void updateContactAvatarUid(const QString& contactUri);

protected:
    using Role = Conversation::Role;

    // Assign a uid for each contact avatar; it will serve as the PictureUid role
    void fillContactAvatarUidMap(const ContactModel::ContactInfoMap& contacts);

    // Convenience pointer to be pulled from lrcinstance
    ConversationModel* model_;

    // AvatarImageProvider helper
    QMap<QString, QString> contactAvatarUidMap_;
};
