/******************************************************************************
 *   Copyright (C) 2014-2025 Savoir-faire Linux Inc.                          *
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

#include <QObject>
#include <QByteArray>
#include <QList>
#include <QMap>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QTimer>

#include "jami.h"
#include "../typedefs.h"
#include "conversions_wrap.hpp"

/*
 * Proxy class for interface org.ring.Ring.Instance
 */
class InstanceManagerInterface : public QObject
{
    Q_OBJECT
public:
    InstanceManagerInterface(bool muteDaemon = false);
    ~InstanceManagerInterface();

    // TODO: These are not present in jami.h

public Q_SLOTS: // METHODS
    void Register(int pid, const QString& name)
    {
        Q_UNUSED(pid) // When directly linked, the PID is always the current process PID
        Q_UNUSED(name)
    }

    void Unregister(int pid)
    {
        Q_UNUSED(pid) // When directly linked, the PID is always the current process PID
        libjami::fini();
    }

    bool isConnected();

private:
Q_SIGNALS: // SIGNALS
    void started();
};

namespace cx {
namespace Ring {
namespace Ring {
typedef ::InstanceManagerInterface Instance;
}
} // namespace Ring
} // namespace cx
