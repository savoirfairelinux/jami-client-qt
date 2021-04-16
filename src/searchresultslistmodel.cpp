/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "searchresultslistmodel.h"

SearchResultsListModel::SearchResultsListModel(LRCInstance* instance, QObject* parent)
    : ConversationListModelBase(instance, parent)
{}

int
SearchResultsListModel::rowCount(const QModelIndex& parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (!parent.isValid() && model_) {
        return searchResults_.size();
    }
    return 0;
}

QVariant
SearchResultsListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    const auto& accountInfo = lrcInstance_->getCurrentAccountInfo();
    const auto& data = model_->getConversations();
    const auto& item = data.at(index.row());

    if (item.participants.size() <= 0) {
        return QVariant();
    }
    auto& contactModel = accountInfo.contactModel;

    // Since we are using image provider right now, image url representation should be unique to
    // be able to use the image cache, account avatar will only be updated once PictureUid changed
    switch (role) {
    case Role::DisplayName: {
        if (!item.participants.isEmpty())
            return QVariant(contactModel->bestNameForContact(item.participants[0]));
        return QVariant("");
    }
    case Role::DisplayID: {
        if (!item.participants.isEmpty())
            return QVariant(contactModel->bestIdForContact(item.participants[0]));
        return QVariant("");
    }
    case Role::Presence: {
        if (!item.participants.isEmpty()) {
            auto& contact = contactModel->getContact(item.participants[0]);
            return QVariant(contact.isPresent);
        }
        return QVariant(false);
    }
    case Role::PictureUid: {
        if (!item.participants.isEmpty()) {
            return QVariant(contactAvatarUidMap_[item.participants[0]]);
        }
        return QVariant("");
    }
    case Role::URI: {
        if (!item.participants.isEmpty()) {
            return QVariant(item.participants[0]);
        }
        return QVariant("");
    }
    case Role::UnreadMessagesCount:
        return QVariant(item.unreadMessages);
    case Role::LastInteractionTimeStamp: {
        if (!item.interactions.empty()) {
            return QVariant(item.interactions.at(item.lastMessageUid).timestamp);
        }
        break;
    }
    case Role::LastInteractionDate: {
        if (!item.interactions.empty()) {
            auto& date = item.interactions.at(item.lastMessageUid).timestamp;
            return QVariant(Utils::formatTimeString(date));
        }
        return QVariant("");
    }
    case Role::LastInteraction: {
        if (!item.interactions.empty()) {
            return QVariant(item.interactions.at(item.lastMessageUid).body);
        }
        return QVariant("");
    }
    case Role::ContactType: {
        if (!item.participants.isEmpty()) {
            auto& contact = contactModel->getContact(item.participants[0]);
            return QVariant(static_cast<int>(contact.profileInfo.type));
        }
        return QVariant(0);
    }
    case Role::UID:
        return QVariant(item.uid);
    case Role::InCall: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty()) {
            auto* callModel = lrcInstance_->getCurrentCallModel();
            return QVariant(callModel->hasCall(convInfo.callId));
        }
        return QVariant(false);
    }
    case Role::IsAudioOnly: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty()) {
            auto* call = lrcInstance_->getCallInfoForConversation(convInfo);
            if (call) {
                return QVariant(call->isAudioOnly);
            }
        }
        return QVariant();
    }
    case Role::CallStackViewShouldShow: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty() && !convInfo.callId.isEmpty()) {
            auto* callModel = lrcInstance_->getCurrentCallModel();
            const auto& call = callModel->getCall(convInfo.callId);
            return QVariant(
                callModel->hasCall(convInfo.callId)
                && ((!call.isOutgoing
                     && (call.status == lrc::api::call::Status::IN_PROGRESS
                         || call.status == lrc::api::call::Status::PAUSED
                         || call.status == lrc::api::call::Status::INCOMING_RINGING))
                    || (call.isOutgoing && call.status != lrc::api::call::Status::ENDED)));
        }
        return QVariant(false);
    }
    case Role::CallState: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty()) {
            if (auto* call = lrcInstance_->getCallInfoForConversation(convInfo)) {
                return QVariant(static_cast<int>(call->status));
            }
        }
        return QVariant();
    }
    case Role::Draft: {
        if (!item.uid.isEmpty()) {
            const auto draft = lrcInstance_->getContentDraft(item.uid, accountInfo.id);
            if (!draft.isEmpty()) {
                // Pencil Emoji
                uint cp = 0x270F;
                auto emojiString = QString::fromUcs4(&cp, 1);
                return emojiString + lrcInstance_->getContentDraft(item.uid, accountInfo.id);
            }
        }
        return QVariant("");
    }
    }
    return QVariant();
}

Qt::ItemFlags
SearchResultsListModel::flags(const QModelIndex& index) const
{
    auto flags = QAbstractItemModel::flags(index) | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable;
    auto type = static_cast<lrc::api::profile::Type>(data(index, Role::ContactType).value<int>());
    auto uid = data(index, Role::UID).value<QString>();
    if (!index.isValid()) {
        return QAbstractItemModel::flags(index);
    } else if ((type == lrc::api::profile::Type::TEMPORARY && uid.isEmpty())) {
        flags &= ~(Qt::ItemIsSelectable);
    }
    return flags;
}

void
SearchResultsListModel::setFilter(const QString& filterString)
{
    model_->setFilter(filterString);
    //    beginResetModel();
    //    fillContactAvatarUidMap(lrcInstance_->getCurrentAccountInfo().contactModel->getAllContacts());
    //    searchResults_ = model_->getAllSearchResults();
    //    endResetModel();
}
