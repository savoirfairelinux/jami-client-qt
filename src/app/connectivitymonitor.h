/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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

#include <QObject>

class ConnectivityMonitor final : public QObject
{
    Q_OBJECT
public:
    explicit ConnectivityMonitor(QObject* parent = nullptr);
    ~ConnectivityMonitor();

    bool isOnline();

Q_SIGNALS:
    void connectivityChanged();

private:
#ifdef Q_OS_WIN
    void destroy();

    struct INetworkListManager* pNetworkListManager_;
    struct IConnectionPointContainer* pCPContainer_;
    struct IConnectionPoint* pConnectPoint_;
    class NetworkEventHandler* netEventHandler_;
    unsigned long cookie_;
#endif // Q_OS_WIN
};
