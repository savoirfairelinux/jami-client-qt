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
#pragma once

#ifdef ENABLE_LIBWRAP
#include "qtwrapper/networkservicemanager_wrap.h"
#else
#include "networkservicemanager_dbus_interface.h"
#include <QDBusPendingReply>
#include "qtwrapper/conversions_wrap.hpp"
#endif
#include <typedefs.h>

namespace NetworkServiceManager {

/// Singleton to access the NetworkServiceManager interface
LIB_EXPORT NetworkServiceManagerInterface& instance();

} // namespace NetworkServiceManager
