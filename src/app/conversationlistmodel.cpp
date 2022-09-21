/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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

#include "conversationlistmodel.h"

#include "uri.h"

ConversationListModel::ConversationListModel(LRCInstance* instance, QObject* parent)
    : ConversationListModelBase(instance, parent)
{}

int
ConversationListModel::rowCount(const QModelIndex& parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (!parent.isValid() && model_) {
        return model_->getConversations().size();
    }
    return 0;
}

QVariant
ConversationListModel::data(const QModelIndex& index, int role) const
{
    const auto& data = model_->getConversations();
    if (!index.isValid() || data.empty())
        return {};
    return dataForItem(data.at(index.row()), role);
}

ConversationListProxyModel::ConversationListProxyModel(QAbstractListModel* model, QObject* parent)
    : SelectableListProxyModel(model, parent)
{
    setSortRole(ConversationList::Role::LastInteractionTimeStamp);
    sort(0, Qt::DescendingOrder);
    setFilterCaseSensitivity(Qt::CaseSensitivity::CaseInsensitive);
}

bool
ConversationListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    auto rx = filterRegularExpression();
    auto uriStripper = URI(rx.pattern());
    bool stripScheme = (uriStripper.schemeType() < URI::SchemeType::COUNT__);
    FlagPack<URI::Section> flags = URI::Section::USER_INFO | URI::Section::HOSTNAME
                                   | URI::Section::PORT;
    if (!stripScheme) {
        flags |= URI::Section::SCHEME;
    }
    rx.setPattern(uriStripper.format(flags));

    using namespace ConversationList;

    QStringList toFilter;
    toFilter += index.data(Role::Title).toString();
    toFilter += index.data(Role::Uris).toStringList();
    toFilter += index.data(Role::Monikers).toStringList();

    // requests
    auto isRequest = index.data(Role::IsRequest).toBool();
    bool requestFilter = filterRequests_ ? isRequest : !isRequest;

    bool match {false};

    // banned contacts require exact match
    if (ignored_.contains(index.data(Role::UID).toString())) {
        match = true;
    } else if (index.data(Role::IsBanned).toBool()) {
        if (!rx.pattern().isEmpty() && rx.isValid()) {
            Q_FOREACH (const auto& filter, toFilter) {
                auto matchResult = rx.match(filter);
                if (matchResult.hasMatch() && matchResult.captured(0) == filter) {
                    match = true;
                    break;
                }
            }
        }
    } else {
        Q_FOREACH (const auto& filter, toFilter)
            if (rx.match(filter).hasMatch()) {
                match = true;
                break;
            }
    }

    return requestFilter && match;
}

bool
ConversationListProxyModel::lessThan(const QModelIndex& left, const QModelIndex& right) const
{
    QVariant leftData = sourceModel()->data(left, sortRole());
    QVariant rightData = sourceModel()->data(right, sortRole());
    // we're assuming the sort role data type here is some integral time
    return leftData.toULongLong() < rightData.toULongLong();
}

void
ConversationListProxyModel::setFilterRequests(bool filterRequests)
{
    beginResetModel();
    filterRequests_ = filterRequests;
    endResetModel();
    updateSelection();
};

// SmartListModel2::SmartListModel2(LRCInstance* instance, QObject* parent)
//    : ConversationListModel(instance, parent)
//{
//    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this,
//    &SmartListModel2::updateData); updateData();
//}

// void
// SmartListModel2::updateData()
//{
//    if (listModelType_ == Type::CONFERENCE) {
//        setConferenceableFilter();
//    } else {
//        beginResetModel();
//        endResetModel();
//    }
//}

// int
// SmartListModel2::rowCount(const QModelIndex& parent) const
//{
//    if (listModelType_ == Type::CONVERSATION || listModelType_ == Type::ADDCONVMEMBER) {
//        return ConversationListModel::rowCount();
//    } else if (listModelType_ == Type::TRANSFER) {
//        auto& accInfo = lrcInstance_->getCurrentAccountInfo();
//        auto convModel = accInfo.conversationModel.get();
//        return convModel->getFilteredConversations(accInfo.profileInfo.type).size();
//    } else if (listModelType_ == Type::CONFERENCE) {
//        auto calls = conferenceables_[ConferenceableItem::CALL];
//        auto contacts = conferenceables_[ConferenceableItem::CONTACT];
//        auto rowCount = contacts.size();
//        if (calls.size()) {
//            rowCount = 2;
//            rowCount += sectionState_[tr("Calls")] ? calls.size() : 0;
//            rowCount += sectionState_[tr("Contacts")] ? contacts.size() : 0;
//        }
//        return rowCount;
//    }
//    return 0;
//}

// QVariant
// SmartListModel2::data(const QModelIndex& index, int role) const
//{
//    if (!index.isValid())
//        return {};

//    switch (listModelType_) {
//    case Type::TRANSFER: {
//        try {
//            auto& currentAccountInfo = lrcInstance_->accountModel().getAccountInfo(
//                lrcInstance_->get_currentAccountId());
//            auto& convModel = currentAccountInfo.conversationModel;

//            auto& item = convModel->getFilteredConversations(currentAccountInfo.profileInfo.type)
//                             .at(index.row());
//            return dataForItem(lrcInstance_, item, role);
//        } catch (const std::exception& e) {
//            qWarning() << e.what();
//        }
//    } break;
//    case Type::CONFERENCE: {
//        auto calls = conferenceables_[ConferenceableItem::CALL];
//        auto contacts = conferenceables_[ConferenceableItem::CONTACT];
//        QString itemConvUid {}, itemAccountId {};
//        if (calls.size() == 0) {
//            itemConvUid = contacts.at(index.row()).at(0).convId;
//            itemAccountId = contacts.at(index.row()).at(0).accountId;
//        } else {
//            bool callsOpen = sectionState_[tr("Calls")];
//            bool contactsOpen = sectionState_[tr("Contacts")];
//            auto callSectionEnd = callsOpen ? calls.size() + 1 : 1;
//            auto contactSectionEnd = contactsOpen ? callSectionEnd + contacts.size() + 1
//                                                  : callSectionEnd + 1;
//            if (index.row() < callSectionEnd) {
//                if (index.row() == 0) {
//                    return QVariant(role == Role::SectionName
//                                        ? (callsOpen ? "➖ " : "➕ ") + QString(tr("Calls"))
//                                        : "");
//                } else {
//                    auto idx = index.row() - 1;
//                    itemConvUid = calls.at(idx).at(0).convId;
//                    itemAccountId = calls.at(idx).at(0).accountId;
//                }
//            } else if (index.row() < contactSectionEnd) {
//                if (index.row() == callSectionEnd) {
//                    return QVariant(role == Role::SectionName
//                                        ? (contactsOpen ? "➖ " : "➕ ") + QString(tr("Contacts"))
//                                        : "");
//                } else {
//                    auto idx = index.row() - (callSectionEnd + 1);
//                    itemConvUid = contacts.at(idx).at(0).convId;
//                    itemAccountId = contacts.at(idx).at(0).accountId;
//                }
//            }
//        }
//        if (role == Role::AccountId) {
//            return QVariant(itemAccountId);
//        }
//        auto& item = lrcInstance_->getConversationFromConvUid(itemConvUid, itemAccountId);
//        return dataForItem(lrcInstance_, item, role);
//    } break;
//    case Type::ADDCONVMEMBER:
//    case Type::CONVERSATION: {
//        return ConversationListModel::data(index, role);
//    } break;
//    default:
//        break;
//    }
//    return {};
//}

// void
// SmartListModel2::setConferenceableFilter(const QString& filter)
//{
//    beginResetModel();
//    auto* convModel = lrcInstance_->getCurrentConversationModel();
//    conferenceables_ = convModel->getConferenceableConversations(lrcInstance_->get_selectedConvUid(),
//                                                                 filter);
//    sectionState_[tr("Calls")] = true;
//    sectionState_[tr("Contacts")] = true;
//    endResetModel();
//}

// void
// SmartListModel2::selectItem(int index)
//{
//    auto contactIndex = QAbstractListModel::index(index, 0);
//    auto* callModel = lrcInstance_->getCurrentCallModel();
//    auto* convModel = lrcInstance_->getCurrentConversationModel();
//    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
//        lrcInstance_->get_selectedConvUid());
//    if (contactIndex.isValid()) {
//        switch (listModelType_) {
//        case SmartListModel2::Type::ADDCONVMEMBER: {
//            auto members = convModel->peersForConversation(lrcInstance_->get_selectedConvUid());
//            auto cntMembers = members.size();
//            const auto uris = contactIndex.data(Role::Uris).toStringList();
//            for (const auto& uri : uris) {
//                // TODO remove < 9
//                if (!members.contains(uri) && cntMembers < 9) {
//                    cntMembers++;
//                    convModel->addConversationMember(lrcInstance_->get_selectedConvUid(), uri);
//                }
//            }
//            break;
//        }
//        case SmartListModel2::Type::CONFERENCE: {
//            // Conference.
//            const auto sectionName = contactIndex.data(Role::SectionName).value<QString>();
//            if (!sectionName.isEmpty()) {
//                toggleSection(sectionName);
//                return;
//            }

//            const auto convUid = contactIndex.data(Role::UID).value<QString>();
//            const auto accId = contactIndex.data(Role::AccountId).value<QString>();
//            const auto callId = lrcInstance_->getCallIdForConversationUid(convUid, accId);

//            if (!callId.isEmpty()) {
//                if (convInfo.uid.isEmpty()) {
//                    return;
//                }
//                auto thisCallId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;

//                callModel->joinCalls(thisCallId, callId);
//            } else {
//                const auto contactUri = contactIndex.data(Role::URI).value<QString>();
//                auto call = lrcInstance_->getCallInfoForConversation(convInfo);
//                if (!call) {
//                    return;
//                }
//                callModel->callAndAddParticipant(contactUri, call->id, call->isAudioOnly);
//            }
//        } break;
//        case SmartListModel2::Type::TRANSFER: {
//            // SIP Transfer.
//            const auto contactUri = contactIndex.data(Role::URI).value<QString>();

//            if (convInfo.uid.isEmpty()) {
//                return;
//            }
//            const auto callId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;

//            QString destCallId;

//            try {
//                // Check if the call exist - (check non-finished calls).
//                const auto callInfo = callModel->getCallFromURI(contactUri, true);
//                destCallId = callInfo.id;
//            } catch (std::exception& e) {
//                qDebug().noquote() << e.what();
//                destCallId = "";
//            }

//            // If no second call -> blind transfer.
//            // If there is a second call -> attended transfer.
//            if (destCallId.size() == 0) {
//                callModel->transfer(callId, "sip:" + contactUri);
//            } else {
//                callModel->transferToCall(callId, destCallId);
//            }
//        } break;
//        case SmartListModel2::Type::CONVERSATION: {
//            const auto contactUri = contactIndex.data(Role::URI).value<QString>();
//            if (contactUri.isEmpty()) {
//                return;
//            }

//            lrcInstance_->accountModel().setDefaultModerator(lrcInstance_->get_currentAccountId(),
//                                                             contactUri,
//                                                             true);
//        } break;
//        default:
//            break;
//        }
//    }
//}

// void
// SmartListModel2::toggleSection(const QString& section)
//{
//    beginResetModel();
//    if (section.contains(tr("Calls"))) {
//        sectionState_[tr("Calls")] ^= true;
//    } else if (section.contains(tr("Contacts"))) {
//        sectionState_[tr("Contacts")] ^= true;
//    }
//    endResetModel();
//}
