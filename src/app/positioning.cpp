/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

Positioning::Positioning(QString uri, QObject* parent)
    : QObject(parent)
    , uri_(uri)
{
    source_ = QGeoPositionInfoSource::createDefaultSource(this);
    QTimer* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &Positioning::requestPosition);
    timer->start(2000);
    connect(source_, &QGeoPositionInfoSource::errorOccurred, this, &Positioning::slotError);
    connect(source_, &QGeoPositionInfoSource::positionUpdated, this, &Positioning::positionUpdated);
    // if location services are activated, positioning will be activated automatically
    connect(source_,
            &QGeoPositionInfoSource::supportedPositioningMethodsChanged,
            this,
            &Positioning::locationServicesActivated);
}

Positioning::~Positioning()
{
    sendStopSharingMsg();
    stop();
}

void
Positioning::start()
{
    source_->startUpdates();
}

void
Positioning::stop()
{
    source_->stopUpdates();
}

void
Positioning::sendStopSharingMsg()
{
    QJsonObject jsonObj;
    jsonObj.insert("type", QJsonValue("Stop"));
    QJsonDocument doc(jsonObj);
    QString strJson(doc.toJson(QJsonDocument::Compact));
    Q_EMIT newPosition(uri_, strJson, -1, "");
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
    Q_EMIT newPosition(uri_, convertToJson(info), -1, "");
}

void
Positioning::requestPosition()
{
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
        return QObject::tr(
            "Location services must be activated in order to show and share your position");
    }
    return QObject::tr("Can't retrieve your position");
}

void
Positioning::slotError(QGeoPositionInfoSource::Error error)
{
    Q_EMIT positioningError(errorToString(error));
}
