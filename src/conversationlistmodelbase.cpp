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

#include "conversationlistmodelbase.h"

ConversationListModelBase::ConversationListModelBase(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    model_ = lrcInstance_->getCurrentConversationModel();
}

int
ConversationListModelBase::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return 1;
}

QHash<int, QByteArray>
ConversationListModelBase::roleNames() const
{
    using namespace Conversation;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CONV_ROLES
#undef X
    return roles;
}

void
ConversationListModelBase::updateContactAvatarUid(const QString& contactUri)
{
    contactAvatarUidMap_[contactUri] = Utils::generateUid();
}

void
ConversationListModelBase::fillContactAvatarUidMap(
    const lrc::api::ContactModel::ContactInfoMap& contacts)
{
    if (contacts.size() == 0) {
        contactAvatarUidMap_.clear();
        return;
    }

    if (contactAvatarUidMap_.isEmpty() || contacts.size() != contactAvatarUidMap_.size()) {
        bool useContacts = contacts.size() > contactAvatarUidMap_.size();
        auto contactsKeyList = contacts.keys();
        auto contactAvatarUidMapKeyList = contactAvatarUidMap_.keys();

        for (int i = 0;
             i < (useContacts ? contactsKeyList.size() : contactAvatarUidMapKeyList.size());
             ++i) {
            // Insert or update
            if (i < contactsKeyList.size() && !contactAvatarUidMap_.contains(contactsKeyList.at(i)))
                contactAvatarUidMap_.insert(contactsKeyList.at(i), Utils::generateUid());
            // Remove
            if (i < contactAvatarUidMapKeyList.size()
                && !contacts.contains(contactAvatarUidMapKeyList.at(i)))
                contactAvatarUidMap_.remove(contactAvatarUidMapKeyList.at(i));
        }
    }
}
