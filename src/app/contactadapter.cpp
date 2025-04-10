/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
        connect(lrcInstance_,
                &LRCInstance::currentAccountIdChanged,
                this,
                &ContactAdapter::connectSignals);
        connectSignals();
    }
}

bool
ContactAdapter::hasDifferentMembers(const VectorString& currentMembers,
                                    const VectorString& convMembers) const
{
    for (const auto& uri : convMembers) {
        if (uri != lrcInstance_->getCurrentAccountInfo().profileInfo.uri
            && !currentMembers.contains(uri))
            return true;
    }
    return false;
}

QVariant
ContactAdapter::getContactSelectableModel(int type)
{
    // Called from qml every time contact picker refreshes.
    listModeltype_ = static_cast<SmartListModel::Type>(type);

    if (listModeltype_ == SmartListModel::Type::CONVERSATION) {
        defaultModerators_ = lrcInstance_->accountModel().getDefaultModerators(
            lrcInstance_->get_currentAccountId());
    }

    smartListModel_.reset(new SmartListModel(this, listModeltype_, lrcInstance_));
    selectableProxyModel_->setSourceModel(smartListModel_.get());

    // Adjust filter.
    switch (listModeltype_) {
    case SmartListModel::Type::CONVERSATION:
        selectableProxyModel_->setPredicate(
            [this](const QModelIndex& index, const QRegularExpression&) {
                return !defaultModerators_.contains(index.data(Role::URI).toString());
            });
        break;
    case SmartListModel::Type::ADDCONVMEMBER: {
        auto currentConvID = lrcInstance_->get_selectedConvUid();
        auto* convModel = lrcInstance_->getCurrentConversationModel();
        auto members = convModel->peersForConversation(currentConvID);
        selectableProxyModel_->setPredicate(
            [this, members](const QModelIndex& index, const QRegularExpression&) {
                return hasDifferentMembers(members, index.data(Role::Uris).toStringList());
            });
        break;
    }
    case SmartListModel::Type::CONFERENCE:
        selectableProxyModel_->setPredicate([](const QModelIndex& index, const QRegularExpression&) {
            return index.data(Role::Presence).toInt();
        });
        break;
    case SmartListModel::Type::TRANSFER:
        selectableProxyModel_->setPredicate([this](const QModelIndex& index,
                                                   const QRegularExpression& regexp) {
            // Exclude current sip callee and filtered contact.
            bool match = true;
            const auto& conv = lrcInstance_->getConversationFromConvUid(
                lrcInstance_->get_selectedConvUid());
            if (!conv.participants.isEmpty()) {
                QString calleeDisplayId = lrcInstance_
                                              ->getAccountInfo(lrcInstance_->get_currentAccountId())
                                              .contactModel->bestIdForContact(
                                                  conv.participants[0].uri);

                QRegularExpression matchExcept = QRegularExpression(
                    QString("\\b(?!" + calleeDisplayId + "\\b)\\w+"));
                match = matchExcept.match(index.data(Role::BestId).toString()).hasMatch();
            }

            if (match) {
                match = regexp.match(index.data(Role::BestId).toString()).hasMatch();
            }
            return match && !index.parent().isValid();
        });
        break;
    default:
        break;
    }
    selectableProxyModel_->invalidate();

    return QVariant::fromValue(selectableProxyModel_.get());
}

void
ContactAdapter::setSearchFilter(const QString& filter)
{
    if (listModeltype_ == SmartListModel::Type::CONFERENCE) {
        smartListModel_->setConferenceableFilter(filter);
    } else if (listModeltype_ == SmartListModel::Type::CONVERSATION) {
        selectableProxyModel_->setPredicate(
            [this, filter](const QModelIndex& index, const QRegularExpression&) {
                return (!defaultModerators_.contains(index.data(Role::URI).toString())
                        && index.data(Role::Title).toString().contains(filter));
            });
    } else if (listModeltype_ == SmartListModel::Type::ADDCONVMEMBER) {
        auto currentConvID = lrcInstance_->get_selectedConvUid();
        auto* convModel = lrcInstance_->getCurrentConversationModel();
        auto members = convModel->peersForConversation(currentConvID);
        selectableProxyModel_->setPredicate([this, filter, members](const QModelIndex& index,
                                                                    const QRegularExpression&) {
            return hasDifferentMembers(members, index.data(Role::Uris).toStringList())
                   && (index.data(Role::Title).toString().contains(filter, Qt::CaseInsensitive)
                       || index.data(Role::RegisteredName)
                              .toString()
                              .contains(filter, Qt::CaseInsensitive)
                       || index.data(Role::Uris).toString().contains(filter, Qt::CaseInsensitive));
        });
    }
    selectableProxyModel_->setFilterRegularExpression(
        QRegularExpression(filter, QRegularExpression::CaseInsensitiveOption));
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
            const auto uris = contactIndex.data(Role::Uris).toStringList();
            for (const auto& uri : uris) {
                if (!members.contains(uri)) {
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
    if (lrcInstance_->get_currentAccountId().isEmpty()) {
        return;
    }

    connect(lrcInstance_->getCurrentContactModel(),
            &ContactModel::bannedStatusChanged,
            this,
            &ContactAdapter::bannedStatusChanged,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentContactModel(),
            &ContactModel::contactAdded,
            this,
            &ContactAdapter::onModelUpdated,
            Qt::UniqueConnection);
}

void
ContactAdapter::onModelUpdated(const QString& uri)
{
    Q_UNUSED(uri)
    // Refresh contacts shown
    selectableProxyModel_->invalidate();
}
