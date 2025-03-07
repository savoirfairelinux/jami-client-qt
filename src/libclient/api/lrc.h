/****************************************************************************
 *   Copyright (C) 2017-2025 Savoir-faire Linux Inc.                        *
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

#include "typedefs.h"

#include <memory>
#include <vector>
#include <atomic>

namespace lrc {

class LrcPimpl;

namespace api {

class BehaviorController;
class AccountModel;
class DataTransferModel;
class AVModel;
class PluginModel;

class LIB_EXPORT Lrc
{
public:
    /**
     * Construct an Lrc object.
     * @param muteDaemon
     */
    Lrc(bool muteDaemon = false);
    ~Lrc();
    /**
     * get a reference on account model.
     * @return a AccountModel&.
     */
    AccountModel& getAccountModel() const;
    /**
     * get a reference on the behavior controller.
     * @return a BehaviorController&.
     */
    BehaviorController& getBehaviorController() const;
    /**
     * get a reference on the audio-video controller.
     * @return a AVModel&.
     */
    AVModel& getAVModel() const;

    /**
     * get a reference on the PLUGIN controller.
     * @return a PluginModel&.
     */
    PluginModel& getPluginModel() const;

    /**
     * Inform the daemon that the connectivity changed
     */
    void connectivityChanged() const;

    /**
     * Test connection with daemon
     */
    static bool isConnected();
    /**
     * Can communicate with the daemon via dbus
     */
    static bool dbusIsValid();
    /**
     * Connect to debugMessageReceived signal
     */
    void subscribeToDebugReceived();

    /**
     * Helper: get active call list from daemon
     */
    static VectorString activeCalls(const QString& accountId = "");

    /**
     * Close all active calls and conferences
     */
    void hangupCallsAndConferences();

    /**
     * Helper: get call list from daemon
     */
    static VectorString getCalls();

    /**
     * Helper: get conference list from daemon
     */
    static VectorString getConferences(const QString& accountId = "");

    /**
     * Get connection list from daemon
     */
    static VectorMapStringString getConnectionList(const QString& accountId, const QString& uid);

    /**
     * Get channel list from daemon
     */
    static VectorMapStringString getChannelList(const QString& accountId, const QString& uid);

    /**
     * Preference
     */
    static std::atomic_bool holdConferences;

    /**
     * Make monitor continous or discrete
     */
    static void monitor(bool continous);

private:
    std::unique_ptr<LrcPimpl> lrcPimpl_;
};

} // namespace api
} // namespace lrc
