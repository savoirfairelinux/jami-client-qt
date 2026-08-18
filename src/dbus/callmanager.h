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
#include "qtwrapper/callmanager_wrap.h"
#else
#include "callmanager_dbus_interface.h"
#include <QDBusPendingReply>

/// Adapts the generated proxy to the method names used by the client, the way
/// qtwrapper/callmanager_wrap.h does in single process mode.
class CallManagerInterface : public CallManagerDBusProxy
{
public:
    using CallManagerDBusProxy::CallManagerDBusProxy;

    QDBusPendingReply<bool> end(const QString& accountId, const QString& callId)
    {
        return hangUp(accountId, callId);
    }

    QDBusPendingReply<bool> endConference(const QString& accountId, const QString& confId)
    {
        return hangUpConference(accountId, confId);
    }

    QDBusPendingReply<bool> decline(const QString& accountId, const QString& callId)
    {
        return refuse(accountId, callId);
    }

    QDBusPendingReply<> disconnectParticipant(const QString& accountId,
                                              const QString& confId,
                                              const QString& accountUri,
                                              const QString& deviceId)
    {
        return hangupParticipant(accountId, confId, accountUri, deviceId);
    }
};
#endif
#include <typedefs.h>

namespace CallManager {

/// Singleton to access dbus "CallManager" interface
LIB_EXPORT CallManagerInterface& instance();

} // namespace CallManager
