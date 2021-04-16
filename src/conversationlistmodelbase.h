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

#include "abstractitemmodelbase.h"

// A generic wrapper view model around ConversationModel's underlying data
class ConversationListModelBase : public AbstractListModelBase
{
    Q_OBJECT

public:
    using AccountInfo = lrc::api::account::Info;
    using ConversationInfo = lrc::api::conversation::Info;
    using ContactInfo = lrc::api::contact::Info;

    // TODO: many of these roles should probably be factored out
    enum Role {
        DisplayName = Qt::UserRole + 1,
        DisplayID,
        Presence,
        URI,
        UnreadMessagesCount,
        LastInteractionTimeStamp,
        LastInteractionDate,
        LastInteraction,
        ContactType,
        UID,
        InCall,
        IsAudioOnly,
        CallStackViewShouldShow,
        CallState,
        AccountId,
        PictureUid,
        Draft
    };
    Q_ENUM(Role)

    explicit ConversationListModelBase(LRCInstance* instance, QObject* parent = nullptr)
        : AbstractListModelBase(parent)
    {
        lrcInstance_ = instance;
        model_ = lrcInstance_->getCurrentConversationModel();
    }

    int columnCount(const QModelIndex& parent) const override
    {
        Q_UNUSED(parent)
        return 1;
    }

    QHash<int, QByteArray> roleNames() const override
    {
        QHash<int, QByteArray> roles;
        roles[DisplayName] = "DisplayName";
        roles[DisplayID] = "DisplayID";
        roles[Presence] = "Presence";
        roles[URI] = "URI";
        roles[UnreadMessagesCount] = "UnreadMessagesCount";
        roles[LastInteractionTimeStamp] = "LastInteractionTimeStamp";
        roles[LastInteractionDate] = "LastInteractionDate";
        roles[LastInteraction] = "LastInteraction";
        roles[ContactType] = "ContactType";
        roles[UID] = "UID";
        roles[InCall] = "InCall";
        roles[IsAudioOnly] = "IsAudioOnly";
        roles[CallStackViewShouldShow] = "CallStackViewShouldShow";
        roles[CallState] = "CallState";
        roles[AccountId] = "AccountId";
        roles[Draft] = "Draft";
        roles[PictureUid] = "PictureUid";
        return roles;
    }

    // Update the avatar uid map to prevent the image provider from pulling from the cache
    Q_INVOKABLE void updateContactAvatarUid(const QString& contactUri)
    {
        contactAvatarUidMap_[contactUri] = Utils::generateUid();
    };

protected:
    // Assign a uid for each contact avatar; it will serve as the PictureUid role
    void fillContactAvatarUidMap(const ContactModel::ContactInfoMap& contacts)
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
                if (i < contactsKeyList.size()
                    && !contactAvatarUidMap_.contains(contactsKeyList.at(i)))
                    contactAvatarUidMap_.insert(contactsKeyList.at(i), Utils::generateUid());
                // Remove
                if (i < contactAvatarUidMapKeyList.size()
                    && !contacts.contains(contactAvatarUidMapKeyList.at(i)))
                    contactAvatarUidMap_.remove(contactAvatarUidMapKeyList.at(i));
            }
        }
    };

    // Convenience pointer to be pulled from lrcinstance
    ConversationModel* model_;

    // AvatarImageProvider helper
    QMap<QString, QString> contactAvatarUidMap_;
};
