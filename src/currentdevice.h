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

#include "lrcinstance.h"
#include "qtutils.h"

#include "api/newdevicemodel.h"

#include <QSortFilterProxyModel>
#include <QObject>

class CurrentDevice;

class CurrentItemFilterModel final : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    explicit CurrentItemFilterModel(QObject* parent = nullptr)
        : QSortFilterProxyModel(parent)

    {}

    void setCurrentItemFilter(const QVariant& filter)
    {
        currentItemFilter_ = filter;
    }

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override
    {
        if (currentItemFilter_.isNull() || sourceModel()->rowCount() == 1)
            return true;

        // Exclude current item filter.
        auto index = sourceModel()->index(sourceRow, 0, sourceParent);
        return index.data(filterRole()) != currentItemFilter_ && !index.parent().isValid();
    }

private:
    QVariant currentItemFilter_ {};
};

class VideoInputDeviceModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { DeviceName = Qt::UserRole + 1, DeviceId };
    Q_ENUM(Role)

    explicit VideoInputDeviceModel(LRCInstance* lrcInstance, CurrentDevice* currentDevice);
    ~VideoInputDeviceModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_ {nullptr};
    CurrentDevice* currentDevice_;
};

class VideoFormatResolutionModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Role { Resolution = Qt::UserRole + 1 };
    Q_ENUM(Role)

    explicit VideoFormatResolutionModel(LRCInstance* lrcInstance, CurrentDevice* currentDevice);
    ~VideoFormatResolutionModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_ {nullptr};
    CurrentDevice* currentDevice_;
};

class VideoFormatFpsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role { FPS = Qt::UserRole + 1, FPS_Float };
    Q_ENUM(Role)

    explicit VideoFormatFpsModel(LRCInstance* lrcInstance, CurrentDevice* currentDevice);
    ~VideoFormatFpsModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reset()
    {
        beginResetModel();
        endResetModel();
    }

    // get model index of the current device
    Q_INVOKABLE int getCurrentIndex() const;

private:
    LRCInstance* lrcInstance_;
    CurrentDevice* currentDevice_;
};

class CurrentDevice : public QObject
{
    Q_OBJECT
    QML_RO_PROPERTY(int, videoDeviceListSize)
    QML_RO_PROPERTY(lrc::api::video::DeviceType, currentRenderingDeviceType)

    QML_RO_PROPERTY(QString, videoDefaultDeviceChannel)
    QML_RO_PROPERTY(QString, videoDefaultDeviceId)
    QML_RO_PROPERTY(QString, videoDefaultDeviceName)
    QML_RO_PROPERTY(QString, videoDefaultDeviceRes)
    QML_RO_PROPERTY(int, videoDefaultDeviceFps)

public:
    explicit CurrentDevice(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CurrentDevice();

    Q_INVOKABLE QVariant videoDeviceFilterModel();
    Q_INVOKABLE QVariant videoDeviceSourceModel();

    Q_INVOKABLE QVariant videoResFilterModel();
    Q_INVOKABLE QVariant videoResSourceModel();

    Q_INVOKABLE QVariant videoFpsFilterModel();
    Q_INVOKABLE QVariant videoFpsSourceModel();

    Q_INVOKABLE void setVideoDefaultDevice(int index, bool useSourceModel = false);
    Q_INVOKABLE void setVideoDefaultDeviceRes(int index);
    Q_INVOKABLE void setVideoDefaultDeviceFps(int index);

    const lrc::api::video::ResRateList& get_videoDefaultDeviceCurrentResRateList();
    void set_videoDefaultDeviceCurrentResRateList(lrc::api::video::ResRateList resRateList);

    const lrc::api::video::FrameratesList& get_videoDefaultDeviceCurrentFpsList();
    void set_videoDefaultDeviceCurrentFpsList(lrc::api::video::FrameratesList rateList);

Q_SIGNALS:
    void videoDeviceAvailable();
    void audioDeviceListChanged(int inputs, int outputs);
    void videoDeviceListChanged(int inputs);

private Q_SLOTS:
    void onAudioDeviceEvent();
    void onVideoDeviceEvent();

private:
    // Used to classify capture device events.
    enum class DeviceEvent { FirstDevice, Added, Removed, None };

    void updateData();

    LRCInstance* lrcInstance_;

    CurrentItemFilterModel* videoDeviceFilterModel_;
    CurrentItemFilterModel* videoResFilterModel_;
    CurrentItemFilterModel* videoFpsFilterModel_;

    VideoInputDeviceModel* videoDeviceSourceModel_;
    VideoFormatResolutionModel* videoResSourceModel_;
    VideoFormatFpsModel* videoFpsSourceModel_;

    lrc::api::video::ResRateList videoDefaultDeviceCurrentResRateList_;
    lrc::api::video::FrameratesList videoDefaultDeviceCurrentFpsList_;
};
