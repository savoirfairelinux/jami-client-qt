/*
 * Copyright (C) 2017-2022 Savoir-faire Linux Inc.
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
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

#include "smartlistmodel.h"

#include "lrcinstance.h"

#include "api/account.h"
#include "api/conversation.h"
#include "api/conversationmodel.h"

#include <QDateTime>

SmartListModel::SmartListModel(QObject* parent)
    : ConversationListModelBase(parent)
{}

void
SmartListModel::onModelUpdated()
{
    if (listModelType_ == Type::CONFERENCE) {
        setConferenceableFilter();
    } else {
        connectModel();
    }
}

int
SmartListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        auto& accInfo = lrcInstance_->getCurrentAccountInfo();
        auto convModel = accInfo.conversationModel.get();
        if (listModelType_ == Type::TRANSFER) {
            return convModel->getFilteredConversations(accInfo.profileInfo.type).size();
        } else if (listModelType_ == Type::CONFERENCE) {
            auto calls = conferenceables_[ConferenceableItem::CALL];
            auto contacts = conferenceables_[ConferenceableItem::CONTACT];
            auto rowCount = contacts.size();
            if (calls.size()) {
                rowCount = 2;
                rowCount += sectionState_[tr("Calls")] ? calls.size() : 0;
                rowCount += sectionState_[tr("Contacts")] ? contacts.size() : 0;
            }
            return rowCount;
        } else {
            const auto& data = lrcInstance_->getCurrentConversationModel()->getConversations();
            return data.size();
        }
    }
    return 0;
}

QVariant
SmartListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return {};

    switch (listModelType_) {
    case Type::TRANSFER: {
        try {
            auto& currentAccountInfo = lrcInstance_->accountModel().getAccountInfo(
                lrcInstance_->get_currentAccountId());
            auto& convModel = currentAccountInfo.conversationModel;

            auto& item = convModel->getFilteredConversations(currentAccountInfo.profileInfo.type)
                             .at(index.row());
            return dataForItem(item, role);
        } catch (const std::exception& e) {
            qWarning() << e.what();
        }
    } break;
    case Type::CONFERENCE: {
        auto calls = conferenceables_[ConferenceableItem::CALL];
        auto contacts = conferenceables_[ConferenceableItem::CONTACT];
        QString itemConvUid {}, itemAccountId {};
        if (calls.size() == 0) {
            itemConvUid = contacts.at(index.row()).at(0).convId;
            itemAccountId = contacts.at(index.row()).at(0).accountId;
        } else {
            bool callsOpen = sectionState_[tr("Calls")];
            bool contactsOpen = sectionState_[tr("Contacts")];
            auto callSectionEnd = callsOpen ? calls.size() + 1 : 1;
            auto contactSectionEnd = contactsOpen ? callSectionEnd + contacts.size() + 1
                                                  : callSectionEnd + 1;
            if (index.row() < callSectionEnd) {
                if (index.row() == 0) {
                    return QVariant(role == Role::SectionName
                                        ? (callsOpen ? "➖ " : "➕ ") + QString(tr("Calls"))
                                        : "");
                } else {
                    auto idx = index.row() - 1;
                    itemConvUid = calls.at(idx).at(0).convId;
                    itemAccountId = calls.at(idx).at(0).accountId;
                }
            } else if (index.row() < contactSectionEnd) {
                if (index.row() == callSectionEnd) {
                    return QVariant(role == Role::SectionName
                                        ? (contactsOpen ? "➖ " : "➕ ") + QString(tr("Contacts"))
                                        : "");
                } else {
                    auto idx = index.row() - (callSectionEnd + 1);
                    itemConvUid = contacts.at(idx).at(0).convId;
                    itemAccountId = contacts.at(idx).at(0).accountId;
                }
            }
        }
        if (role == Role::AccountId) {
            return QVariant(itemAccountId);
        }

        auto& item = lrcInstance_->getConversationFromConvUid(itemConvUid, itemAccountId);
        return dataForItem(item, role);
    } break;
    case Type::ADDCONVMEMBER:
    case Type::CONVERSATION: {
        const auto& data = lrcInstance_->getCurrentConversationModel()->getConversations();
        auto& item = data.at(index.row());
        return dataForItem(item, role);
    } break;
    default:
        break;
    }
    return {};
}

void
SmartListModel::setConferenceableFilter(const QString& filter)
{
    beginResetModel();
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    conferenceables_ = convModel->getConferenceableConversations(lrcInstance_->get_selectedConvUid(),
                                                                 filter);
    sectionState_[tr("Calls")] = true;
    sectionState_[tr("Contacts")] = true;
    endResetModel();
}

void
SmartListModel::selectItem(int index)
{
    auto contactIndex = SmartListModel::index(index, 0);
    auto* callModel = lrcInstance_->getCurrentCallModel();
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    if (contactIndex.isValid()) {
        switch (listModelType_) {
        case SmartListModel::Type::ADDCONVMEMBER: {
            auto members = convModel->peersForConversation(lrcInstance_->get_selectedConvUid());
            auto cntMembers = members.size();
            const auto uris = contactIndex.data(Role::Uris).toStringList();
            for (const auto& uri : uris) {
                // TODO remove < 9
                if (!members.contains(uri) && cntMembers < 9) {
                    cntMembers++;
                    convModel->addConversationMember(lrcInstance_->get_selectedConvUid(), uri);
                }
            }
            break;
        }
        case SmartListModel::Type::CONFERENCE: {
            // Conference.
            const auto sectionName = contactIndex.data(Role::SectionName).value<QString>();
            if (!sectionName.isEmpty()) {
                toggleSection(sectionName);
                return;
            }

            const auto convUid = contactIndex.data(Role::UID).value<QString>();
            const auto accId = contactIndex.data(Role::AccountId).value<QString>();
            const auto callId = lrcInstance_->getCallIdForConversationUid(convUid, accId);

            if (!callId.isEmpty()) {
                if (convInfo.uid.isEmpty()) {
                    return;
                }
                auto thisCallId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;

                callModel->joinCalls(thisCallId, callId);
            } else {
                const auto contactUri = contactIndex.data(Role::URI).value<QString>();
                auto call = lrcInstance_->getCallInfoForConversation(convInfo);
                if (!call) {
                    return;
                }
                callModel->callAndAddParticipant(contactUri, call->id, call->isAudioOnly);
            }
        } break;
        case SmartListModel::Type::TRANSFER: {
            // SIP Transfer.
            const auto contactUri = contactIndex.data(Role::URI).value<QString>();

            if (convInfo.uid.isEmpty()) {
                return;
            }
            const auto callId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;

            QString destCallId;

            try {
                // Check if the call exist - (check non-finished calls).
                const auto callInfo = callModel->getCallFromURI(contactUri, true);
                destCallId = callInfo.id;
            } catch (std::exception& e) {
                qDebug().noquote() << e.what();
                destCallId = "";
            }

            // If no second call -> blind transfer.
            // If there is a second call -> attended transfer.
            if (destCallId.size() == 0) {
                callModel->transfer(callId, "sip:" + contactUri);
            } else {
                callModel->transferToCall(callId, destCallId);
            }
        } break;
        case SmartListModel::Type::CONVERSATION: {
            const auto contactUri = contactIndex.data(Role::URI).value<QString>();
            if (contactUri.isEmpty()) {
                return;
            }

            lrcInstance_->accountModel().setDefaultModerator(lrcInstance_->get_currentAccountId(),
                                                             contactUri,
                                                             true);
        } break;
        default:
            break;
        }
    }
}

void
SmartListModel::toggleSection(const QString& section)
{
    beginResetModel();
    if (section.contains(tr("Calls"))) {
        sectionState_[tr("Calls")] ^= true;
    } else if (section.contains(tr("Contacts"))) {
        sectionState_[tr("Contacts")] ^= true;
    }
    endResetModel();
}
