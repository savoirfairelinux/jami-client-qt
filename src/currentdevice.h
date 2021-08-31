/*!
 * Copyright (C) 2020 by Savoir-faire Linux
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

#include "qtutils.h"

#include <QSortFilterProxyModel>
#include <QObject>

class LRCInstance;

class CurrentItemFilterModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit CurrentItemFilterModel(QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)
    {}

    void setCurrentItemFilterString(const QString& filter)
    {
        currentItemFilterString_ = filter;
    }

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        if (currentItemFilterString_.isEmpty())
            return false;

        // Exclude current item filter.
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        QRegExp matchExcept = QRegExp(QString("\\b(?!" + currentItemFilterString_ + "\\b)\\w+"));
        bool match = matchExcept.indexIn(index.data(filterRole()).toString()) != -1;

        return match && !index.parent().isValid();
    }

private:
    QString currentItemFilterString_ {};
};

class VideoInputDeviceModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { DeviceName = Qt::UserRole + 1 };
    Q_ENUM(Role)

    explicit VideoInputDeviceModel(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~VideoInputDeviceModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset();

private:
    LRCInstance* lrcInstance_ {nullptr};
};

class VideoFormatResolutionModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { Resolution = Qt::UserRole + 1 };
    Q_ENUM(Role)

    explicit VideoFormatResolutionModel(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~VideoFormatResolutionModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset();

private:
    LRCInstance* lrcInstance_ {nullptr};
};

class VideoFormatFpsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role { FPS = Qt::UserRole + 1 };
    Q_ENUM(Role)

    explicit VideoFormatFpsModel(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~VideoFormatFpsModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset();

private:
    LRCInstance* lrcInstance_;
};

class CurrentDevice : public QObject
{
    Q_OBJECT
    QML_RO_PROPERTY(lrc::api::video::DeviceType, currentRenderingDeviceType)
    QML_RO_PROPERTY(QString, videoDefaultDeviceName)
    QML_RO_PROPERTY(QString, videoDefaultDeviceRes)
    QML_RO_PROPERTY(float, videoDefaultDeviceFps)
public:
    explicit CurrentDevice(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CurrentDevice();

private:
    LRCInstance* lrcInstance_;

    CurrentItemFilterModel* videoDeviceFilterModel_;
    CurrentItemFilterModel* videoResFilterModel_;
    CurrentItemFilterModel* videoFpsFilterModel_;
};
