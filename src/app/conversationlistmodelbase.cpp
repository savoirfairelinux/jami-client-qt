/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    try {
        auto& accInfo = lrcInstance_->getCurrentAccountInfo();
        accountId_ = accInfo.id;
        model_ = accInfo.conversationModel.get();
    } catch (...) {
    }
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
    using namespace ConversationList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CONV_ROLES
#undef X
    return roles;
}

QVariant
ConversationListModelBase::dataForItem(item_t item, int role) const
{
    auto& accInfo = lrcInstance_->getAccountInfo(accountId_);
    switch (role) {
    case Role::InCall: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty()) {
            return QVariant(accInfo.callModel->hasCall(convInfo.callId));
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
        return QVariant(false);
    }
    case Role::CallStackViewShouldShow: {
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(item.uid);
        if (!convInfo.uid.isEmpty() && !convInfo.callId.isEmpty()) {
            const auto& call = accInfo.callModel->getCall(convInfo.callId);
            return QVariant(accInfo.callModel->hasCall(convInfo.callId)
                            && ((!call.isOutgoing
                                 && (call.status == call::Status::IN_PROGRESS
                                     || call.status == call::Status::PAUSED
                                     || call.status == call::Status::INCOMING_RINGING))
                                || (call.isOutgoing && call.status != call::Status::ENDED)));
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
        return {};
    }
    case Role::Draft: {
        if (!item.uid.isEmpty())
            return lrcInstance_->getContentDraft(item.uid, item.accountId);
        return {};
    }
    case Role::ActiveCallsCount: {
        return item.activeCalls.size();
    }
    case Role::IsRequest:
        return QVariant(item.isRequest);
    case Role::Title:
        return QVariant(model_->title(item.uid));
    case Role::UnreadMessagesCount:
        return QVariant(item.unreadMessages);
    case Role::LastInteractionTimeStamp: {
        qint32 ts = 0;
        item.interactions->withLast([&ts](const QString&, const interaction::Info& interaction) {
            ts = interaction.timestamp;
        });
        return QVariant(ts);
    }
    case Role::LastInteraction: {
        QString lastInteractionBody;
        item.interactions->withLast([&](const QString&, const interaction::Info& interaction) {
            auto& accInfo = lrcInstance_->getCurrentAccountInfo();
            if (interaction.type == interaction::Type::DATA_TRANSFER) {
                lastInteractionBody = interaction.commit.value("displayName");
            } else if (interaction.type == lrc::api::interaction::Type::CALL) {
                const auto isOutgoing = interaction.authorUri == accInfo.profileInfo.uri;
                lastInteractionBody = interaction::getCallInteractionString(isOutgoing, interaction);
            } else if (interaction.type == lrc::api::interaction::Type::CONTACT) {
                auto bestName = interaction.authorUri == accInfo.profileInfo.uri
                                    ? accInfo.accountModel->bestNameForAccount(accInfo.id)
                                    : accInfo.contactModel->bestNameForContact(
                                        interaction.authorUri);
                lastInteractionBody
                    = interaction::getContactInteractionString(bestName,
                                                               interaction::to_action(
                                                                   interaction.commit["action"]));
            } else
                lastInteractionBody = interaction.body;
        });
        return QVariant(lastInteractionBody);
    }
    case Role::IsSwarm:
        return QVariant(item.isSwarm());
    case Role::IsCoreDialog:
        return QVariant(item.isCoreDialog());
    case Role::Mode:
        return QVariant(static_cast<int>(item.mode));
    case Role::UID:
        return QVariant(item.uid);
    case Role::IsBanned:
        if (!item.isCoreDialog()) {
            return false;
        }
        break;
    case Role::Uris:
        return QVariant(model_->peersForConversation(item.uid).toList());
    case Role::Monikers: {
        // we shouldn't ever need these individually, they are used for filtering only
        QStringList ret;
        Q_FOREACH (const auto& peerUri, model_->peersForConversation(item.uid))
            try {
                auto& accInfo = lrcInstance_->getAccountInfo(accountId_);
                auto contact = accInfo.contactModel->getContact(peerUri);
                ret << contact.profileInfo.alias << contact.registeredName;
            } catch (const std::exception&) {
            }
        return ret;
    }
    case Role::Presence: {
        // The conversation can show a green dot if at least one peer is present
        Q_FOREACH (const auto& peerUri, model_->peersForConversation(item.uid))
            try {
                auto& accInfo = lrcInstance_->getAccountInfo(accountId_);
                if (peerUri == accInfo.profileInfo.uri)
                    return true; // Self account
                auto contact = accInfo.contactModel->getContact(peerUri);
                if (contact.isPresent)
                    return true;
            } catch (const std::exception&) {
            }
        return false;
    };
    default:
        break;
    }

    if (item.isCoreDialog()) {
        auto peerUriList = model_->peersForConversation(item.uid);
        if (peerUriList.isEmpty())
            return {};
        auto peerUri = peerUriList.at(0);
        auto& accInfo = lrcInstance_->getAccountInfo(accountId_);
        if (peerUri == accInfo.profileInfo.uri) {
            // Conversation alone with self
            switch (role) {
            case Role::BestId:
                return QVariant(lrcInstance_->accountModel().bestIdForAccount(accInfo.id));
            case Role::Alias:
                return QVariant(accInfo.profileInfo.alias);
            case Role::RegisteredName:
                return QVariant(accInfo.registeredName);
            case Role::URI:
                return QVariant(peerUri);
            case Role::IsBanned:
                return QVariant(false);
            case Role::ContactType:
                return QVariant(static_cast<int>(accInfo.profileInfo.type));
            }
        }
        ContactModel* contactModel;
        contact::Info contact {};
        contactModel = accInfo.contactModel.get();
        try {
            contact = contactModel->getContact(peerUri);
        } catch (const std::exception&) {
            qWarning() << Q_FUNC_INFO << "Can't find contact" << peerUri << " for account "
                       << lrcInstance_->accountModel().bestNameForAccount(accInfo.id)
                       << " - Conv: " << item.uid;
        }

        switch (role) {
        case Role::BestId:
            return QVariant(contactModel->bestIdForContact(peerUri));
        case Role::Alias:
            return QVariant(contact.profileInfo.alias);
        case Role::RegisteredName:
            return QVariant(contact.registeredName);
        case Role::URI:
            return QVariant(peerUri);
        case Role::IsBanned:
            return QVariant(contact.isBanned);
        case Role::ContactType:
            return QVariant(static_cast<int>(contact.profileInfo.type));
        }
    }

    return {};
}
