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

#pragma once

#include "qmladapterbase.h"

#include <QObject>
#include <QQmlEngine>
#include <QApplication>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include <map>
#include <memory>

/*!
 * Exposes the daemon's shared-services / peer-tunnel API to QML.
 *
 * Local services configured by the user are listed/edited via
 * getSharedServices / addSharedService / updateSharedService /
 * removeSharedService. To discover what a remote peer exposes, call
 * queryPeerServices(peerUri) — the result is delivered asynchronously
 * via the peerServicesReceived signal, correlated by requestId.
 *
 * Tunnels are opened with openServiceTunnel and listed with
 * getActiveTunnels; tunnelOpened fires once a local TCP listener is
 * ready, tunnelClosed when it is torn down.
 */
class SharedServicesAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

public:
    static SharedServicesAdapter* create(QQmlEngine*, QJSEngine*);

    explicit SharedServicesAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~SharedServicesAdapter() override;

    // ----- Local shared services (per account) -------------------------------

    /// Returns a list of QVariantMap describing the services shared by
    /// `accountId` (or by the current account when empty). Each map
    /// contains the keys: id, type, name, description, localHost, localPort,
    /// directory, policy ("public"|"contacts"|"specific"), allowedContacts (CSV),
    /// enabled ("true"|"false").
    Q_INVOKABLE QVariantList getSharedServices(const QString& accountId = {});

    /// Add a new shared service. Returns the generated service id, or
    /// empty on failure. `service` mirrors the map shape returned by
    /// getSharedServices (id is ignored).
    Q_INVOKABLE QString addSharedService(const QString& accountId, const QVariantMap& service);

    /// Update an existing service (keyed by service.id). Returns true on
    /// success.
    Q_INVOKABLE bool updateSharedService(const QString& accountId, const QVariantMap& service);

    /// Remove the shared service with the given id.
    Q_INVOKABLE bool removeSharedService(const QString& accountId, const QString& serviceId);

    // ----- Peer service discovery -------------------------------------------

    /// Asynchronously query the services shared by `peerUri`. The
    /// response is delivered via peerServicesReceived; the returned
    /// requestId can be used by callers to correlate.
    Q_INVOKABLE quint32 queryPeerServices(const QString& accountId, const QString& peerUri);

    /// Status codes for `peerServicesReceived`. Mirrors
    /// `libjami::ServiceSignal::PeerServicesStatus`.
    enum class PeerServicesStatus : int {
        OK = 0,
        NoDevices = 1,
        Unreachable = 2,
        Timeout = 3,
        InternalError = 4,
    };
    Q_ENUM(PeerServicesStatus)

    // ----- Tunnels ----------------------------------------------------------

    /// Open a TCP tunnel to a peer device's service. Returns the tunnel
    /// id (or empty on failure). Pass localPort=0 to let the OS pick a
    /// free port; the actual bound port is reported by tunnelOpened.
    Q_INVOKABLE QString openServiceTunnel(const QString& accountId,
                                          const QString& peerUri,
                                          const QString& peerDevice,
                                          const QString& serviceId,
                                          const QString& serviceName,
                                          quint16 localPort = 0);

    Q_INVOKABLE bool closeServiceTunnel(const QString& accountId, const QString& tunnelId);

    /// Returns active tunnels for the account. Each map has: id,
    /// peerUri, deviceId, serviceId, serviceName, localPort.
    Q_INVOKABLE QVariantList getActiveTunnels(const QString& accountId = {}) const;

Q_SIGNALS:
    /// Asynchronous response to queryPeerServices(). Emitted exactly once
    /// per request id. `status` is one of `PeerServicesStatus`. `services`
    /// is decoded from the daemon's JSON; each entry has id, name,
    /// description, proto. Empty list for any non-OK status.
    void peerServicesReceived(
        quint32 requestId, const QString& accountId, const QString& peerUri, int status, const QVariantList& services);

    void tunnelOpened(const QString& accountId, const QString& tunnelId, quint16 localPort);

    void tunnelClosed(const QString& accountId, const QString& tunnelId, const QString& reason);

    void refreshSharedServices();

private:
    struct EmbeddedServer;

    QString resolveAccountId(const QString& accountId) const;
    QString embeddedServerKey(const QString& accountId, const QString& serviceId) const;
    bool prepareServiceForStorage(const QString& accountId,
                                  QVariantMap& service,
                                  std::unique_ptr<EmbeddedServer>& replacementServer);
    std::unique_ptr<EmbeddedServer> startEmbeddedServer(const QString& accountId,
                                                        const QString& serviceId,
                                                        const QString& directory,
                                                        quint16 requestedPort);
    void syncAllEmbeddedServers();
    void syncEmbeddedServers(const QString& accountId);
    void stopEmbeddedServer(const QString& accountId, const QString& serviceId);
    void stopEmbeddedServersForAccount(const QString& accountId);

    std::map<QString, std::unique_ptr<EmbeddedServer>> embeddedServers_;
};
Q_DECLARE_METATYPE(SharedServicesAdapter*)