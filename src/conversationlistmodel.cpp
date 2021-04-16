/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

ConversationListModel::ConversationListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    model_ = lrcInstance_->getCurrentConversationModel();

    connect(
        model_,
        &ConversationModel::beginInsertRows,
        this,
        [this](int position, int rows) {
            beginInsertRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);
    connect(model_,
            &ConversationModel::endInsertRows,
            this,
            &ConversationListModel::endInsertRows,
            Qt::DirectConnection);

    connect(
        model_,
        &ConversationModel::beginRemoveRows,
        this,
        [this](int position, int rows) {
            beginRemoveRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);
    connect(model_,
            &ConversationModel::endRemoveRows,
            this,
            &ConversationListModel::endRemoveRows,
            Qt::DirectConnection);

    connect(model_, &ConversationModel::dataChanged, this, [this](int position) {
        const auto index = createIndex(position, 0);
        Q_EMIT ConversationListModel::dataChanged(index, index);
    });
}

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

int
ConversationListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return 1;
}

QVariant
ConversationListModel::data(const QModelIndex& index, int role) const
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
    case Role::LastInteractionType: {
        if (!item.interactions.empty()) {
            return QVariant(static_cast<int>(item.interactions.at(item.lastMessageUid).type));
        }
        return QVariant(0);
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

QHash<int, QByteArray>
ConversationListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DisplayName] = "DisplayName";
    roles[DisplayID] = "DisplayID";
    roles[Presence] = "Presence";
    roles[URI] = "URI";
    roles[UnreadMessagesCount] = "UnreadMessagesCount";
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

Qt::ItemFlags
ConversationListModel::flags(const QModelIndex& index) const
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
ConversationListModel::updateContactAvatarUid(const QString& contactUri)
{
    contactAvatarUidMap_[contactUri] = Utils::generateUid();
}

void
ConversationListModel::fillContactAvatarUidMap(const ContactModel::ContactInfoMap& contacts)
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

ConversationListProxyModel::ConversationListProxyModel(QAbstractListModel* model, QObject* parent)
    : QSortFilterProxyModel(parent)
    , selectedSourceIndex_(QModelIndex())
{
    qDebug() << "ConversationListProxyModel";
    setSourceModel(model);
    setSortRole(ConversationListModel::Role::LastInteractionDate);
    sort(0, Qt::DescendingOrder);
    connect(sourceModel(),
            &QAbstractListModel::dataChanged,
            this,
            &ConversationListProxyModel::updateSelection);
    connect(sourceModel(),
            &QAbstractListModel::rowsInserted,
            this,
            &ConversationListProxyModel::updateSelection);
    connect(sourceModel(),
            &QAbstractListModel::rowsRemoved,
            this,
            &ConversationListProxyModel::updateSelection);
}

bool
ConversationListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    int filterRole = ConversationListModel::Role::DisplayName;
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    return (index.data(filterRole).toString().contains(filterRegExp()));
}

bool
ConversationListProxyModel::lessThan(const QModelIndex& left, const QModelIndex& right) const
{
    QVariant leftData = sourceModel()->data(left, sortRole());
    QVariant rightData = sourceModel()->data(right, sortRole());

    return leftData.toUInt() < rightData.toUInt();
}

void
ConversationListProxyModel::setFilter(const QString& filterString)
{
    setFilterRegExp(filterString);
    updateSelection();
}

void
ConversationListProxyModel::select(const QModelIndex& index)
{
    selectedSourceIndex_ = mapToSource(index);
    updateSelection();
}

void
ConversationListProxyModel::select(int row)
{
    select(index(row, 0));
}

int
ConversationListProxyModel::currentFilteredRow()
{
    return currentFilteredRow_;
}

QVariant
ConversationListProxyModel::dataForRow(int row, int role) const
{
    return data(index(row, 0), role);
}

void
ConversationListProxyModel::setCurrentFilteredRow(int currentFilteredRow)
{
    if (currentFilteredRow_ == currentFilteredRow)
        return;
    currentFilteredRow_ = currentFilteredRow;
    Q_EMIT currentFilteredRowChanged(currentFilteredRow_);
}

void
ConversationListProxyModel::updateSelection()
{
    auto filteredIndex = mapFromSource(selectedSourceIndex_);

    // if the source model is empty, invalidate the selection
    if (sourceModel()->rowCount() == 0) {
        setCurrentFilteredRow(-1);
        Q_EMIT validSelectionChanged();
        return;
    }

    // if the source and filtered index is no longer valid
    // this would indicate that a mutation has occured,
    // thus any arbritrary ux decision is okay here
    if (!selectedSourceIndex_.isValid()) {
        auto row = qMax(--currentFilteredRow_, 0);
        selectedSourceIndex_ = mapToSource(index(row, 0));
        filteredIndex = mapFromSource(selectedSourceIndex_);
        currentFilteredRow_ = filteredIndex.row();
        Q_EMIT currentFilteredRowChanged(currentFilteredRow_);
        Q_EMIT validSelectionChanged();
        return;
    }

    // update the row for ListView observers
    setCurrentFilteredRow(filteredIndex.row());

    // finally, if the filter index is invalid, then we have
    // probably just filtered out the selected item and don't
    // want to force reselection of other ui components, as the
    // source index is still valid
    if (filteredIndex.isValid())
        Q_EMIT validSelectionChanged();
}
