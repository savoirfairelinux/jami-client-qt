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
#pragma once

#include <QtPositioning/QGeoPositionInfoSource>
#include <QObject>
#include <QString>
#include <QTimer>

class Positioning : public QObject
{
    Q_OBJECT

public:
    Positioning(QString uri, QObject* parent = 0)
        : QObject(parent)
        , uri_(uri)
        , source_(QGeoPositionInfoSource::createDefaultSource(this))
    {
        QTimer* timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, &Positioning::requestPosition);
        timer->start(2000);
        connect(source_, &QGeoPositionInfoSource::errorOccurred, this, &Positioning::slotError);
        connect(source_, &QGeoPositionInfoSource::positionUpdated, this, &Positioning::posUpdated);
        // if location services are activated, positioning will be activated automatically
        connect(source_,
                &QGeoPositionInfoSource::supportedPositioningMethodsChanged,
                this,
                &Positioning::startPositioning);
    }
    ~Positioning()
    {
        sendStopSharingMsg();
        stopPositioning();
    }

    void startPositioning();
    void stopPositioning();
    void sendStopSharingMsg();
    QString convertToJson(const QGeoPositionInfo& info);

private Q_SLOTS:
    void slotError(QGeoPositionInfoSource::Error error);
    void posUpdated(const QGeoPositionInfo& info);
    void requestPosition();

Q_SIGNALS:
    void newPos(const QString& peerId,
                const QString& body,
                const uint64_t& timestamp,
                const QString& daemonId);
    void positioningError(const int error);

private:
    QString uri_;
    QGeoPositionInfoSource* source_;
};
