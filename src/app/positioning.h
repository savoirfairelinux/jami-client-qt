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
#pragma once

#include <QtPositioning/QGeoPositionInfoSource>
#include <QObject>
#include <QString>
#include <QTimer>

class Positioning : public QObject
{
    Q_OBJECT

public:
    Positioning(QObject* parent = 0);
    /**
     * start to retreive the current position
     */
    void start();
    /**
     * stop to retreive the current position
     */
    void stop();
    /**
     * send a stop signal to other peers to tell them
     * you stoped sharing yout position
     */
    QString convertToJson(const QGeoPositionInfo& info);

private Q_SLOTS:
    void slotError(QGeoPositionInfoSource::Error error);
    void positionUpdated(const QGeoPositionInfo& info);
    /**
     * Force to send position at regular intervals
     */
    void requestPosition();
    /**
     * Triggered when location services are activated
     */
    void locationServicesActivated();

Q_SIGNALS:
    void newPosition(const QString& body);
    void positioningError(const QString error);

private:
    QString uri_;
    QGeoPositionInfoSource* source_ = nullptr;
    bool isPositioning = false;
    QTimer* timer_;
};
