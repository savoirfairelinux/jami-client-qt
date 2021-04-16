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

#include <QSortFilterProxyModel>

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
    void updateContactAvatarUid(const QString& contactUri)
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

// The base class for a filtered and sorted model.
// The model may be part of a group and if so, will track a
// mutually exclusive selection.
class SelectableListProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_PROPERTY(int, currentFilteredRow)

public:
    explicit SelectableListProxyModel(QAbstractListModel* model, QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)
        , currentFilteredRow_(-1)
        , selectedSourceIndex_(QModelIndex())
    {
        setSourceModel(model);
        connect(sourceModel(),
                &QAbstractListModel::dataChanged,
                this,
                &SelectableListProxyModel::updateSelection);
        connect(sourceModel(),
                &QAbstractListModel::rowsInserted,
                this,
                &SelectableListProxyModel::updateSelection);
        connect(sourceModel(),
                &QAbstractListModel::rowsRemoved,
                this,
                &SelectableListProxyModel::updateSelection);
    }

    Q_INVOKABLE void setFilter(const QString& filterString)
    {
        setFilterRegExp(filterString);
        updateSelection();
    };

    Q_INVOKABLE void select(const QModelIndex& index)
    {
        selectedSourceIndex_ = mapToSource(index);
        updateSelection();
    };

    Q_INVOKABLE void select(int row)
    {
        select(index(row, 0));
    };

    Q_INVOKABLE QVariant dataForRow(int row, int role = Qt::DisplayRole) const
    {
        return data(index(row, 0), role);
    };

    // this may not be the best place for this but it prevents a level of
    // inheritance and prevents code duplication
    Q_INVOKABLE void updateContactAvatarUid(const QString& contactUri)
    {
        // cast from QAbstractItemModel -> ConversationListModelBase
        auto base = qobject_cast<ConversationListModelBase*>(sourceModel());
        if (base)
            base->updateContactAvatarUid(contactUri);
    };

public Q_SLOTS:
    void updateSelection()
    {
        // if there has been no valid selection made, there is
        // nothing to update
        if (!selectedSourceIndex_.isValid() && currentFilteredRow_ == -1)
            return;

        auto filteredIndex = mapFromSource(selectedSourceIndex_);

        // if the source model is empty, invalidate the selection
        if (sourceModel()->rowCount() == 0) {
            set_currentFilteredRow(-1);
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
            Q_EMIT currentFilteredRowChanged();
            Q_EMIT validSelectionChanged();
            return;
        }

        // update the row for ListView observers
        set_currentFilteredRow(filteredIndex.row());

        // finally, if the filter index is invalid, then we have
        // probably just filtered out the selected item and don't
        // want to force reselection of other ui components, as the
        // source index is still valid
        if (filteredIndex.isValid())
            Q_EMIT validSelectionChanged();
    };

Q_SIGNALS:
    void validSelectionChanged();

private:
    QPersistentModelIndex selectedSourceIndex_;
};

class SelectableListProxyGroupModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(int, currentFilteredRow)

public:
    explicit SelectableListProxyGroupModel(QList<SelectableListProxyModel*> models,
                                           QObject* parent = nullptr)
        : QObject(parent)
        , models_(models)
    {
        Q_FOREACH (auto* m, models_) {
            connect(m, &SelectableListProxyModel::validSelectionChanged, [this] {
                // deselect others
            });
        }
    }
    QList<SelectableListProxyModel*> models_;
};
