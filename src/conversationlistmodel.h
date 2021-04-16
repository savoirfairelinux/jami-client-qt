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

#pragma once

#include "abstractlistmodelbase.h"

#include <QSortFilterProxyModel>

// A wrapper view model around ConversationModel's underlying data
class ConversationListModel : public AbstractListModelBase
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

    explicit ConversationListModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // Update the avatar uid map to prevent the image provider from pulling from the cache
    Q_INVOKABLE void updateContactAvatarUid(const QString& contactUri);

private:
    // Assign a uid for each contact avatar; it will serve as the PictureUid role
    void fillContactAvatarUidMap(const ContactModel::ContactInfoMap& contacts);

private:
    // Convenience pointer to be pulled from lrcinstance
    ConversationModel* model_;

    // AvatarImageProvider helper
    QMap<QString, QString> contactAvatarUidMap_;
};

// The top level filtered and sorted model to be consumed by QML ListViews
class ConversationListProxyModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int currentFilteredRow READ currentFilteredRow WRITE setCurrentFilteredRow NOTIFY
                   currentFilteredRowChanged)

public:
    explicit ConversationListProxyModel(QAbstractListModel* model, QObject* parent = nullptr);

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

    Q_INVOKABLE void setFilter(const QString& filterString);
    Q_INVOKABLE void select(const QModelIndex& index);
    Q_INVOKABLE void select(int row);
    Q_INVOKABLE int currentFilteredRow();
    Q_INVOKABLE QVariant dataForRow(int row, int role = Qt::DisplayRole) const;

public Q_SLOTS:
    void setCurrentFilteredRow(int currentFilteredRow);

private Q_SLOTS:
    void updateSelection();

Q_SIGNALS:
    void currentFilteredRowChanged(int currentFilteredRow);
    void validSelectionChanged();

private:
    // A cut down replacement for QItemSelectionModel
    QPersistentModelIndex selectedSourceIndex_;
    int currentFilteredRow_ {-1};
};
