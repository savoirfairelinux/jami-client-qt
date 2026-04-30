/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include "exposedservicesadapter.h"

#include "lrcinstance.h"

#include "dbus/configurationmanager.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QString>

namespace {

QVariantMap
mapToVariant(const MapStringString& m)
{
    QVariantMap out;
    for (auto it = m.cbegin(); it != m.cend(); ++it)
        out.insert(it.key(), it.value());
    return out;
}

MapStringString
variantToMap(const QVariantMap& v)
{
    MapStringString out;
    for (auto it = v.cbegin(); it != v.cend(); ++it)
        out.insert(it.key(), it.value().toString());
    return out;
}

} // namespace

ExposedServicesAdapter*
ExposedServicesAdapter::create(QQmlEngine*, QJSEngine*)
{
    return new ExposedServicesAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
}

ExposedServicesAdapter::ExposedServicesAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    auto& cm = ConfigurationManager::instance();

    connect(&cm,
            &ConfigurationManagerInterface::peerServicesReceived,
            this,
            [this](quint32 requestId,
                   const QString& accountId,
                   const QString& peerId,
                   int status,
                   const QString& servicesJson) {
                QVariantList services;
                QJsonParseError err;
                auto doc = QJsonDocument::fromJson(servicesJson.toUtf8(), &err);
                if (err.error == QJsonParseError::NoError && doc.isArray()) {
                    const auto arr = doc.array();
                    services.reserve(arr.size());
                    for (const auto& v : arr)
                        services.append(v.toObject().toVariantMap());
                }
                Q_EMIT peerServicesReceived(requestId, accountId, peerId, status, services);
            });

    connect(&cm,
            &ConfigurationManagerInterface::serviceTunnelOpened,
            this,
            [this](const QString& accountId, const QString& tunnelId, quint16 localPort) {
                Q_EMIT tunnelOpened(accountId, tunnelId, localPort);
            });

    connect(&cm,
            &ConfigurationManagerInterface::serviceTunnelClosed,
            this,
            [this](const QString& accountId, const QString& tunnelId, const QString& reason) {
                Q_EMIT tunnelClosed(accountId, tunnelId, reason);
            });
}

QString
ExposedServicesAdapter::resolveAccountId(const QString& accountId) const
{
    if (!accountId.isEmpty())
        return accountId;
    if (lrcInstance_)
        return lrcInstance_->get_currentAccountId();
    return {};
}

QVariantList
ExposedServicesAdapter::getExposedServices(const QString& accountId) const
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    const auto records = ConfigurationManager::instance().getExposedServices(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}

QString
ExposedServicesAdapter::addExposedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return {};
    return ConfigurationManager::instance().addExposedService(id, variantToMap(service));
}

bool
ExposedServicesAdapter::updateExposedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return false;
    return ConfigurationManager::instance().updateExposedService(id, variantToMap(service));
}

bool
ExposedServicesAdapter::removeExposedService(const QString& accountId, const QString& serviceId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || serviceId.isEmpty())
        return false;
    return ConfigurationManager::instance().removeExposedService(id, serviceId);
}

quint32
ExposedServicesAdapter::queryPeerServices(const QString& accountId, const QString& peerUri)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || peerUri.isEmpty())
        return 0;
    return ConfigurationManager::instance().queryPeerServices(id, peerUri);
}

QString
ExposedServicesAdapter::openServiceTunnel(const QString& accountId,
                                          const QString& peerUri,
                                          const QString& peerDevice,
                                          const QString& serviceId,
                                          const QString& serviceName,
                                          quint16 localPort)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return {};
    return ConfigurationManager::instance().openServiceTunnel(id, peerUri, peerDevice, serviceId, serviceName, localPort);
}

bool
ExposedServicesAdapter::closeServiceTunnel(const QString& accountId, const QString& tunnelId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || tunnelId.isEmpty())
        return false;
    return ConfigurationManager::instance().closeServiceTunnel(id, tunnelId);
}

QVariantList
ExposedServicesAdapter::getActiveTunnels(const QString& accountId) const
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    const auto records = ConfigurationManager::instance().getActiveTunnels(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}
