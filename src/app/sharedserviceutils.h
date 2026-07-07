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

#include <QVariant>

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

} // namespace SharedServiceUtils
