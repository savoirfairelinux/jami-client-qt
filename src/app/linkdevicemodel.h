/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "api/account.h"

#include "qmladapterbase.h"
#include "qtutils.h"

#include <QObject>
#include <QVariant>
#include <QMap>

class LRCInstance;

class LinkDeviceModel : public QObject
{
    Q_OBJECT
    QML_PROPERTY(QString, tokenErrorMessage);
    QML_PROPERTY(QString, linkDeviceError);
    QML_PROPERTY(int, deviceAuthState);
    QML_PROPERTY(QString, ipAddress);

public:
    explicit LinkDeviceModel(LRCInstance* lrcInstance, QObject* parent = nullptr);

    Q_INVOKABLE void addDevice(const QString& token);

    Q_INVOKABLE void confirmAddDevice();
    Q_INVOKABLE void cancelAddDevice();
    Q_INVOKABLE void reset();

private:
    bool checkNewStateValidity(lrc::api::account::DeviceAuthState newState) const;
    void handleConnectingSignal();
    void handleAuthenticatingSignal(const QVariantMap& details);
    void handleInProgressSignal();
    void handleDoneSignal(const QVariantMap& details);

    LRCInstance* lrcInstance_ = nullptr;
    uint32_t operationId_;
};
