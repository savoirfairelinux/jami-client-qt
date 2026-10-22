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

#include <QMap>
#include <QVariant>

#include <algorithm>

namespace SharedServiceUtils {

constexpr quint16 PREFERRED_PORT_MIN = 1024;
constexpr quint16 PREFERRED_PORT_MAX = 65535;

inline quint16
sanitizePreferredPort(const QVariant& value)
{
    bool ok = false;
    const auto port = value.toString().toUInt(&ok);
    if (!ok || port < PREFERRED_PORT_MIN || port > PREFERRED_PORT_MAX)
        return 0;
    return static_cast<quint16>(port);
}

/*!
 * The services some contacts offer, gathered from their answers as they come.
 * Each one is a service as its contact described it, plus who offers it:
 * peerUri and peerName.
 */
class OfferedServices
{
public:
    /// Starts over, waiting for each of these contacts (uri: name) to answer.
    void expect(const QMap<QString, QString>& contacts)
    {
        waiting_ = contacts;
        services_.clear();
    }

    /// A contact's answer, with its services if it could tell them. Returns
    /// false when this contact's answer is not awaited.
    bool receive(const QString& peerUri, bool answered, const QVariantList& services)
    {
        const auto contact = waiting_.constFind(peerUri);
        if (contact == waiting_.constEnd())
            return false;
        const auto peerName = contact.value();
        waiting_.remove(peerUri);
        if (!answered)
            return true;
        for (const auto& service : services) {
            auto offered = service.toMap();
            offered["peerUri"] = peerUri;
            offered["peerName"] = peerName;
            services_.append(offered);
        }
        std::stable_sort(services_.begin(), services_.end(), [](const QVariant& a, const QVariant& b) {
            const auto first = a.toMap();
            const auto second = b.toMap();
            const auto byPeer = first["peerName"].toString().compare(second["peerName"].toString(), Qt::CaseInsensitive);
            if (byPeer != 0)
                return byPeer < 0;
            return first["name"].toString().compare(second["name"].toString(), Qt::CaseInsensitive) < 0;
        });
        return true;
    }

    bool waiting() const
    {
        return !waiting_.isEmpty();
    }

    const QVariantList& services() const
    {
        return services_;
    }

private:
    QMap<QString, QString> waiting_;
    QVariantList services_;
};

} // namespace SharedServiceUtils
