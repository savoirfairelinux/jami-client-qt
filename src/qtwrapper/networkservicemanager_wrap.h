/******************************************************************************
 *   Copyright (C) 2014-2026 Savoir-faire Linux Inc.                          *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/
#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QMap>

#include <networkservice_interface.h>

#include "typedefs.h"
#include "conversions_wrap.hpp"

/*
 * Proxy class for the network service (shared services / tunnels) interface.
 */
class NetworkServiceManagerInterface : public QObject
{
    Q_OBJECT

public:
    std::map<std::string, std::shared_ptr<libjami::CallbackWrapperBase>> serviceHandlers;

    NetworkServiceManagerInterface()
    {
        setObjectName("NetworkServiceManagerInterface");
        using libjami::exportable_callback;
        using libjami::ServiceSignal;

        serviceHandlers = {
            exportable_callback<ServiceSignal::PeerServicesReceived>([this](uint32_t requestId,
                                                                            const std::string& accountId,
                                                                            const std::string& peerId,
                                                                            int status,
                                                                            const std::string& servicesJson) {
                Q_EMIT this->peerServicesReceived(requestId,
                                                  QString(accountId.c_str()),
                                                  QString(peerId.c_str()),
                                                  status,
                                                  QString(servicesJson.c_str()));
            }),
            exportable_callback<ServiceSignal::TunnelOpened>(
                [this](const std::string& accountId, const std::string& tunnelId, uint16_t localPort) {
                    Q_EMIT this->serviceTunnelOpened(QString(accountId.c_str()), QString(tunnelId.c_str()), localPort);
                }),
            exportable_callback<ServiceSignal::TunnelClosed>(
                [this](const std::string& accountId, const std::string& tunnelId, const std::string& reason) {
                    Q_EMIT this->serviceTunnelClosed(QString(accountId.c_str()),
                                                     QString(tunnelId.c_str()),
                                                     QString(reason.c_str()));
                }),
        };
    }

    VectorMapStringString getSharedServices(const QString& accountId)
    {
        return convertVecMap(libjami::getExposedServices(accountId.toStdString()));
    }

    QString addSharedService(const QString& accountId, MapStringString service)
    {
        return QString::fromStdString(libjami::addExposedService(accountId.toStdString(), convertMap(service)));
    }

    bool updateSharedService(const QString& accountId, MapStringString service)
    {
        return libjami::updateExposedService(accountId.toStdString(), convertMap(service));
    }

    bool removeSharedService(const QString& accountId, const QString& serviceId)
    {
        return libjami::removeExposedService(accountId.toStdString(), serviceId.toStdString());
    }

    uint32_t queryPeerServices(const QString& accountId, const QString& peerUri)
    {
        return libjami::queryPeerServices(accountId.toStdString(), peerUri.toStdString());
    }

    QString openServiceTunnel(const QString& accountId,
                              const QString& peerUri,
                              const QString& peerDevice,
                              const QString& serviceId,
                              const QString& serviceName,
                              uint16_t localPort)
    {
        return QString::fromStdString(libjami::openServiceTunnel(accountId.toStdString(),
                                                                 peerUri.toStdString(),
                                                                 peerDevice.toStdString(),
                                                                 serviceId.toStdString(),
                                                                 serviceName.toStdString(),
                                                                 localPort));
    }

    bool closeServiceTunnel(const QString& accountId, const QString& tunnelId)
    {
        return libjami::closeServiceTunnel(accountId.toStdString(), tunnelId.toStdString());
    }

    VectorMapStringString getActiveTunnels(const QString& accountId)
    {
        return convertVecMap(libjami::getActiveTunnels(accountId.toStdString()));
    }

Q_SIGNALS:
    void peerServicesReceived(
        uint32_t requestId, const QString& accountId, const QString& peerId, int status, const QString& servicesJson);
    void serviceTunnelOpened(const QString& accountId, const QString& tunnelId, quint16 localPort);
    void serviceTunnelClosed(const QString& accountId, const QString& tunnelId, const QString& reason);
};
