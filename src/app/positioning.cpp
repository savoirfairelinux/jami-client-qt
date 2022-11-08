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

void
Positioning::startPositioning()
{
    // qDebug() << " positioning started";

    // qDebug() << "source: " << source;
    if (source_) {
        source_->startUpdates();
    }
    stopPositioning();
}

void
Positioning::stopPositioning()
{
    // qDebug() << " positioning stoped";
    source_->stopUpdates();
}

void
Positioning::stopSharingMessage()
{
    QString temp;
    temp = "{\"type\":\"Stop\"}";
    Q_EMIT newPos(uri_, temp, -1, "");
}

QString
Positioning::convertToJson(const QGeoPositionInfo& info)
{
    QString temp = "{\"type\":\"Position\","
                   "\"lat\":"
                   + QString::number(info.coordinate().latitude())
                   + ","
                     "\"long\":"
                   + QString::number(info.coordinate().longitude())
                   + ","
                     "\"time\":"
                   + QString::number(info.timestamp().toMSecsSinceEpoch()) + "}";
    return temp;
}

void
Positioning::posUpdated(const QGeoPositionInfo& info)
{
    Q_EMIT newPos(uri_, convertToJson(info), -1, "");
    // qDebug() << "Position updated:" << info;
}

void
Positioning::updatePos()
{
    startPositioning();
    // qDebug() << "Position forced updated:";
}
void
Positioning::slotError(QGeoPositionInfoSource::Error error)
{
    qDebug() << "positioning failed:" << error;
    if (error == QGeoPositionInfoSource::Error::AccessError) {
        qDebug() << " try to activate to activate localisation service ";
        stopPositioning();
    }
}
