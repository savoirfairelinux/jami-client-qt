/*
 * Copyright (C) 2015-2026 Savoir-faire Linux Inc.
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

#include <array>
#include <memory>
#include <utility>

#define PROPERTY_GETTER_BASE(type, prop) \
    type prop##_ {}; \
\
public: \
    Q_SIGNAL void prop##Changed(); \
    type get_##prop() \
    { \
        return prop##_; \
    }

#define PROPERTY_SETTER_BASE(type, prop) \
    void set_##prop(const type& x = {}) \
    { \
        if (prop##_ != x) { \
            prop##_ = x; \
            Q_EMIT prop##Changed(); \
        } \
    }

#define PROPERTY_BASE(type, prop) \
    PROPERTY_GETTER_BASE(type, prop) \
    PROPERTY_SETTER_BASE(type, prop)

#define QML_RO_PROPERTY(type, prop) \
private: \
    Q_PROPERTY(type prop READ get_##prop NOTIFY prop##Changed); \
    PROPERTY_BASE(type, prop)

#define QML_PROPERTY(type, prop) \
private: \
    Q_PROPERTY(type prop MEMBER prop##_ NOTIFY prop##Changed); \
    PROPERTY_BASE(type, prop)

namespace Utils {

template<typename Sender, typename Signal, typename Slot, typename Interrupter, typename InterrupterSignal>
void
connectSingleShotUntil(const Sender* sender,
                       Signal signal,
                       const QObject* context,
                       Slot&& slot,
                       const Interrupter* interrupter,
                       InterrupterSignal interrupterSignal)
{
    auto connections = std::make_shared<std::array<QMetaObject::Connection, 3>>();
    auto disconnectAll = [connections] {
        for (const auto& connection : *connections)
            QObject::disconnect(connection);
    };
    const auto connectionType = static_cast<Qt::ConnectionType>(Qt::DirectConnection | Qt::SingleShotConnection);
    (*connections)[0] = QObject::connect(sender, signal, context, std::forward<Slot>(slot), connectionType);
    (*connections)[1] = QObject::connect(sender, signal, context, disconnectAll, connectionType);
    (*connections)[2] = QObject::connect(interrupter, interrupterSignal, context, disconnectAll, connectionType);
}

} // namespace Utils
