/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
#include "pttlistener.h"

#include <QAbstractListModel>
#include <QObject>
#include <QQmlEngine>
#include <QSortFilterProxyModel>
#include <QQuickItem>

#define PC_ROLES \
    X(PrimaryName) \
    X(PendingConferenceeCallId) \
    X(CallStatus) \
    X(ContactUri)

namespace CallControl {
Q_NAMESPACE
enum Role { ItemAction = Qt::UserRole + 1, UrgentCount, Enabled };
Q_ENUM_NS(Role)

struct Item
{
    QObject* itemAction;
    bool enabled {true};
    int urgentCount {0};
};
} // namespace CallControl

namespace PendingConferences {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    PC_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace PendingConferences

class IndexRangeFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit IndexRangeFilterProxyModel(QAbstractListModel* parent = nullptr);

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;

    void setRange(int min, int max);

private:
    int min_ {-1};
    int max_ {-1};
};

class PendingConferenceesListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    PendingConferenceesListModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void connectSignals();

private:
    LRCInstance* lrcInstance_ {nullptr};

    QMetaObject::Connection callsStatusChanged_;
    QMetaObject::Connection beginInsertPendingConferencesRows_;
    QMetaObject::Connection endInsertPendingConferencesRows_;
    QMetaObject::Connection beginRemovePendingConferencesRows_;
    QMetaObject::Connection endRemovePendingConferencesRows_;
};

class CallControlListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    CallControlListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setUrgentCount(QVariant item, int count);
    void setEnabled(QObject* obj, bool enabled);
    void addItem(const CallControl::Item& item);
    void clearData();

private:
    QList<CallControl::Item> data_;
};

class CallOverlayModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(int, overflowIndex)

public:
    CallOverlayModel(LRCInstance* instance, PTTListener* listener, QObject* parent = nullptr);

    Q_INVOKABLE void addPrimaryControl(const QVariant& action, bool enabled);
    Q_INVOKABLE void addSecondaryControl(const QVariant& action, bool enabled);
    Q_INVOKABLE void setUrgentCount(QVariant item, int count);
    Q_INVOKABLE void setEnabled(QObject* obj, bool enabled);
    Q_INVOKABLE void clearControls();

    Q_INVOKABLE QVariant primaryModel();
    Q_INVOKABLE QVariant secondaryModel();
    Q_INVOKABLE QVariant overflowModel();
    Q_INVOKABLE QVariant overflowVisibleModel();
    Q_INVOKABLE QVariant overflowHiddenModel();
    Q_INVOKABLE QVariant pendingConferenceesModel();

    Q_INVOKABLE void setEventFilterActive(QObject* object, QQuickItem* item, bool isActive);
    bool eventFilter(QObject* object, QEvent* event) override;

Q_SIGNALS:
    void mouseMoved(QQuickItem* item);
    void focusKeyPressed();
    void pttKeyPressed();
    void pttKeyReleased();

private Q_SLOTS:
    void setControlRanges();

private:
    LRCInstance* lrcInstance_ {nullptr};

    CallControlListModel* primaryModel_;
    CallControlListModel* secondaryModel_;
    IndexRangeFilterProxyModel* overflowModel_;
    IndexRangeFilterProxyModel* overflowVisibleModel_;
    IndexRangeFilterProxyModel* overflowHiddenModel_;
    PendingConferenceesListModel* pendingConferenceesModel_;

    QList<QQuickItem*> watchedItems_;

#ifndef HAVE_GLOBAL_PTT
    PTTListener* listener_ {nullptr};
#endif
};
