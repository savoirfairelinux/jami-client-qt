/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "positioning.h"

#include <QJsonObject>
#include <QJsonDocument>

Positioning::Positioning(QObject* parent)
    : QObject(parent)
{
    source_ = QGeoPositionInfoSource::createDefaultSource(this);
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &Positioning::requestPosition);

    // There are several reasons QGeoPositionInfoSource::createDefaultSource may return
    // null. For example, if the device has no geolocation providers, or if the device has no
    // location services activated. This seems to be the case for our QML testing fixture. Ideally,
    // we would like to listen to system signals to know when location services are activated.
    if (source_) {
        connect(source_, &QGeoPositionInfoSource::errorOccurred, this, &Positioning::slotError);
        connect(source_,
                &QGeoPositionInfoSource::positionUpdated,
                this,
                &Positioning::positionUpdated);
        // If location services are activated, positioning will be activated automatically.
        connect(source_,
                &QGeoPositionInfoSource::supportedPositioningMethodsChanged,
                this,
                &Positioning::locationServicesActivated);
    }
}

void
Positioning::start()
{
    requestPosition();
    timer_->start(10000);
    if (source_ && !isPositioning) {
        source_->startUpdates();
        isPositioning = true;
    }
}

void
Positioning::stop()
{
    if (source_ && isPositioning)
        source_->stopUpdates();
    isPositioning = false;
    timer_->stop();
}

QString
Positioning::convertToJson(const QGeoPositionInfo& info)
{
    QJsonObject jsonObj;
    jsonObj.insert("type", QJsonValue("Position"));
    jsonObj.insert("lat", QJsonValue(info.coordinate().latitude()));
    jsonObj.insert("long", QJsonValue(info.coordinate().longitude()));
    jsonObj.insert("time", QJsonValue(info.timestamp().toMSecsSinceEpoch()));

    QJsonDocument doc(jsonObj);
    QString strJson(doc.toJson(QJsonDocument::Compact));

    return strJson;
}

void
Positioning::positionUpdated(const QGeoPositionInfo& info)
{
    Q_EMIT positioningError("");
    Q_EMIT newPosition(convertToJson(info));
}

void
Positioning::requestPosition()
{
    if (source_)
        source_->requestUpdate();
}

void
Positioning::locationServicesActivated()
{
    Q_EMIT positioningError("");
    start();
}

static QString
errorToString(QGeoPositionInfoSource::Error error)
{
    if (error == 0) {
        return QObject::tr("locationServicesError");
    }
    if (error == 1) {
        return QObject::tr("locationServicesClosedError");
    }
    return QObject::tr("locationServicesUnknownError");
}

void
Positioning::slotError(QGeoPositionInfoSource::Error error)
{
    Q_EMIT positioningError(errorToString(error));
}
