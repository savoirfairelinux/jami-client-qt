/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

#include "lrcinstance.h"
#include "qtutils.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>
#include <QJsonObject>

#define CALL_PARTICIPANTS_ROLES \
    X(Uri) \
    X(Device) \
    X(SinkId) \
    X(BestName) \
    X(Avatar) \
    X(Active) \
    X(XPosition) \
    X(YPosition) \
    X(Width) \
    X(Height) \
    X(AudioLocalMuted) \
    X(AudioModeratorMuted) \
    X(VideoMuted) \
    X(IsModerator) \
    X(IsLocal) \
    X(IsContact)

namespace CallParticipant {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CALL_PARTICIPANTS_ROLES
#undef X
};
Q_ENUM_NS(Role)

struct Item
{
    QJsonObject item;

    bool operator==(const Item& a) const
    {
        return (item == a.item);
    }
};
} // namespace CallParticipant

/*
 * The CurrentAccountFilterModel class
 * is for the sole purpose of filtering out current account.
 */
class GenericParticipantsFilterModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit GenericParticipantsFilterModel(LRCInstance* lrcInstance,
                                            QAbstractListModel* parent = nullptr)
        : QSortFilterProxyModel(parent)
        , lrcInstance_(lrcInstance)
    {
        setSourceModel(parent);
        setFilterRole(CallParticipant::Role::Active);
    }

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        // Accept all participants in participants list filtered with active status.
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        return !sourceModel()->data(index, CallParticipant::Role::Active).toBool();
    }

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

protected:
    LRCInstance* lrcInstance_ {nullptr};
};

/*
 * The ActiveParticipantsFilterModel class
 * is for the sole purpose of filtering out current account.
 */
class ActiveParticipantsFilterModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit ActiveParticipantsFilterModel(LRCInstance* lrcInstance,
                                           QAbstractListModel* parent = nullptr)
        : QSortFilterProxyModel(parent)
        , lrcInstance_(lrcInstance)
    {
        setSourceModel(parent);
        setFilterRole(CallParticipant::Role::Active);
    }

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        // Accept all participants in participants list filtered with active status.
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        return sourceModel()->data(index, CallParticipant::Role::Active).toBool();
    }

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

protected:
    LRCInstance* lrcInstance_ {nullptr};
};

class CallParticipantsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(LayoutType conferenceLayout READ conferenceLayout NOTIFY layoutChanged)
public:
    CallParticipantsModel(LRCInstance* instance, QObject* parent = nullptr);

    typedef enum { GRID = 0, ONE_WITH_SMALL, ONE } LayoutType;
    Q_ENUM(LayoutType);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateParticipant(int index, const QVariant& infos);
    void addParticipant(int index, const QVariant& infos);
    void removeParticipant(int index);
    void clearParticipantsRenderes(const QString& callId);
    void setParticipants(const QString& callId, const QVariantList& participants);
    void resetParticipants(const QString& callId, const QVariantList& participants);
    Q_INVOKABLE void reset();
    void setConferenceLayout(int layout, const QString& callId)
    {
        auto newLayout = static_cast<LayoutType>(layout);
        if (callId == callId_ && newLayout != layout_) {
            layout_ = newLayout;
            Q_EMIT layoutChanged();
        }
    }
    const LayoutType conferenceLayout()
    {
        return layout_;
    }

Q_SIGNALS:
    void updateParticipant(QVariant participantInfos);
    void layoutChanged();

private:
    LRCInstance* lrcInstance_ {nullptr};

    QList<CallParticipant::Item> participants_ {};
    QMap<QString, QStringList> renderers_ {};
    QString callId_;
    LayoutType layout_;
};
