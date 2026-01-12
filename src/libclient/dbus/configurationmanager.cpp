/****************************************************************************
 *   Copyright (C) 2009-2026 Savoir-faire Linux Inc.                        *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "configurationmanager.h"

#include "../globalinstances.h"
#include "../interfaces/dbuserrorhandleri.h"

ConfigurationManagerInterface&
ConfigurationManager::instance()
{
#ifdef ENABLE_LIBWRAP
    static auto interface = new ConfigurationManagerInterface();
#else
    if (!dbus_metaTypeInit)
        registerCommTypes();
    static auto interface = new ConfigurationManagerInterface("cx.ring.Ring",
                                                              "/cx/ring/Ring/ConfigurationManager",
                                                              QDBusConnection::sessionBus());
    if (!interface->connection().isConnected()) {
        GlobalInstances::dBusErrorHandler().connectionError(
            "Error: jamid not connected. Service " + interface->service()
            + " is not connected. From configuration manager interface.");
    }
    if (!interface->isValid()) {
        GlobalInstances::dBusErrorHandler().invalidInterfaceError(
            "Error: jamid is unavailable, make sure it is running");
    }
#endif
    return *interface;
}
