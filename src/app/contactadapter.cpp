/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
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

#include "contactadapter.h"

#include "lrcinstance.h"

ContactAdapter::ContactAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    selectableProxyModel_.reset(new SelectableProxyModel(this));
    if (lrcInstance_) {
        connectSignals();
        connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, [this] {
            connectSignals();
        });
    }
}

void
ContactAdapter::setConferenceableFilter(const QString& filter)
{
    smartListModel_->setConferenceableFilter(filter);
}

void
ContactAdapter::contactSelected(int index)
{
    auto contactIndex = selectableProxyModel_->index(index, 0);
    auto* callModel = lrcInstance_->getCurrentCallModel();
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    if (contactIndex.isValid()) {
        switch (listModeltype_) {
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
                smartListModel_->toggleSection(sectionName);
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
            Q_EMIT defaultModeratorsUpdated();

        } break;
        default:
            break;
        }
    }
}

void
ContactAdapter::removeContact(const QString& peerUri, bool banContact)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    accInfo.contactModel->removeContact(peerUri, banContact);
}

void
ContactAdapter::connectSignals()
{
    if (lrcInstance_->getCurrentContactModel())
        connect(lrcInstance_->getCurrentContactModel(),
                &ContactModel::bannedStatusChanged,
                this,
                &ContactAdapter::bannedStatusChanged,
                Qt::UniqueConnection);
}
