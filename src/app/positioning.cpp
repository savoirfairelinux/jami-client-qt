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
    if (source_) {
        source_->startUpdates();
    }
}

void
Positioning::stopPositioning()
{
    source_->stopUpdates();
}

void
Positioning::sendStopSharingMsg()
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
}

void
Positioning::requestPosition()
{
    source_->requestUpdate();
}

void
Positioning::slotError(QGeoPositionInfoSource::Error error)
{
    qDebug() << "positioning failed:" << error;
    stopPositioning();
    Q_EMIT positioningError(error);
}
