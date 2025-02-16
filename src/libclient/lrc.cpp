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
#include "api/lrc.h"

#if !defined(_MSC_VER)
#include <unistd.h>
#endif

#include "call_const.h"

// Models and database
#include "api/avmodel.h"
#include "api/pluginmodel.h"
#include "api/behaviorcontroller.h"
#include "api/accountmodel.h"
#include "callbackshandler.h"
#include "dbus/callmanager.h"
#include "dbus/configurationmanager.h"
#include "dbus/instancemanager.h"
#include "dbus/configurationmanager.h"

Q_LOGGING_CATEGORY(libclientLog, "libclient")

namespace lrc {

using namespace api;

std::atomic_bool lrc::api::Lrc::holdConferences;

// To judge whether the call is finished or not depending on callState
bool isFinished(const QString& callState);

class LrcPimpl
{
public:
    LrcPimpl(Lrc& linked);

    const Lrc& linked;
    std::unique_ptr<BehaviorController> behaviorController;
    std::unique_ptr<CallbacksHandler> callbackHandler;
    std::unique_ptr<AccountModel> accountModel;
    std::unique_ptr<AVModel> AVModel_;
    std::unique_ptr<PluginModel> PluginModel_;
};

Lrc::Lrc(bool muteDaemon)
{
    lrc::api::Lrc::holdConferences.store(true);
#ifndef ENABLE_LIBWRAP
    // Replace locale for timestamps
    std::locale::global(std::locale(""));
#else
#ifdef Q_OS_LINUX
    if (!getenv("JAMI_DISABLE_SHM"))
        setenv("JAMI_DISABLE_SHM", "1", true);
#endif
#endif
    // Ensure Daemon is running/loaded (especially on non-DBus platforms)
    // before instantiating LRC and its members
    InstanceManager::instance(muteDaemon);
    lrcPimpl_ = std::make_unique<LrcPimpl>(*this);
}

Lrc::~Lrc()
{
    // Unregister from the daemon
    InstanceManagerInterface& instance = InstanceManager::instance();
    Q_NOREPLY instance.Unregister(getpid());
#ifndef ENABLE_LIBWRAP
    instance.connection().disconnectFromBus(instance.connection().baseService());
#endif // ENABLE_LIBWRAP
}

AccountModel&
Lrc::getAccountModel() const
{
    return *lrcPimpl_->accountModel;
}

BehaviorController&
Lrc::getBehaviorController() const
{
    return *lrcPimpl_->behaviorController;
}

AVModel&
Lrc::getAVModel() const
{
    return *lrcPimpl_->AVModel_;
}

PluginModel&
Lrc::getPluginModel() const
{
    return *lrcPimpl_->PluginModel_;
}

void
Lrc::connectivityChanged() const
{
    ConfigurationManager::instance().connectivityChanged();
}

bool
Lrc::isConnected()
{
#ifdef ENABLE_LIBWRAP
    return true;
#else
    return ConfigurationManager::instance().connection().isConnected();
#endif
}

bool
Lrc::dbusIsValid()
{
#ifdef ENABLE_LIBWRAP
    return true;
#else
    return ConfigurationManager::instance().isValid();
#endif
}

void
Lrc::subscribeToDebugReceived()
{
    lrcPimpl_->callbackHandler->subscribeToDebugReceived();
}

VectorString
Lrc::activeCalls(const QString& accountId)
{
    VectorString result;
    const QStringList accountIds = ConfigurationManager::instance().getAccountList();
    for (const auto& accId : accountIds) {
        if (!accountId.isEmpty() && accountId != accId)
            continue;
        QStringList callLists = CallManager::instance().getCallList(accId);
        for (const auto& call : callLists) {
            MapStringString callDetails = CallManager::instance().getCallDetails(accId, call);
            if (!isFinished(callDetails[QString(libjami::Call::Details::CALL_STATE)]))
                result.push_back(call);
        }
    }
    return result;
}

void
Lrc::hangupCallsAndConferences()
{
    const QStringList accountIds = ConfigurationManager::instance().getAccountList();
    for (const auto& accId : accountIds) {
        QStringList conferences = CallManager::instance().getConferenceList(accId);
        for (const auto& conf : conferences) {
            CallManager::instance().hangUpConference(accId, conf);
        }
        QStringList calls = CallManager::instance().getCallList(accId);
        for (const auto& call : calls) {
            CallManager::instance().hangUp(accId, call);
        }
    }
}

VectorString
Lrc::getCalls()
{
    QStringList callLists = CallManager::instance().getCallList("");
    VectorString result;
    result.reserve(callLists.size());
    for (const auto& call : callLists) {
        result.push_back(call);
    }
    return result;
}

VectorString
Lrc::getConferences(const QString& accountId)
{
    VectorString result;
    if (accountId.isEmpty()) {
        const QStringList accountIds = ConfigurationManager::instance().getAccountList();
        for (const auto& accId : accountIds) {
            QStringList conferencesList = CallManager::instance().getConferenceList(accId);
            for (const auto& conf : conferencesList)
                result.push_back(conf);
        }
    } else {
        QStringList conferencesList = CallManager::instance().getConferenceList(accountId);
        for (const auto& conf : conferencesList)
            result.push_back(conf);
    }
    return result;
}

VectorMapStringString
Lrc::getConnectionList(const QString& accountId, const QString& uid)
{
    return ConfigurationManager::instance().getConnectionList(accountId, uid);
}

VectorMapStringString
Lrc::getChannelList(const QString& accountId, const QString& uid)
{
    return ConfigurationManager::instance().getChannelList(accountId, uid);
}

bool
isFinished(const QString& callState)
{
    if (callState == QLatin1String(libjami::Call::StateEvent::HUNGUP)
        || callState == QLatin1String(libjami::Call::StateEvent::BUSY)
        || callState == QLatin1String(libjami::Call::StateEvent::PEER_BUSY)
        || callState == QLatin1String(libjami::Call::StateEvent::FAILURE)
        || callState == QLatin1String(libjami::Call::StateEvent::INACTIVE)
        || callState == QLatin1String(libjami::Call::StateEvent::OVER)) {
        return true;
    }
    return false;
}

void
Lrc::monitor(bool continuous)
{
    ConfigurationManager::instance().monitor(continuous);
}

LrcPimpl::LrcPimpl(Lrc& linked)
    : linked(linked)
    , behaviorController(std::make_unique<BehaviorController>())
    , callbackHandler(std::make_unique<CallbacksHandler>(linked))
    , accountModel(std::make_unique<AccountModel>(linked, *callbackHandler, *behaviorController))
    , AVModel_ {std::make_unique<AVModel>(*callbackHandler)}
    , PluginModel_ {std::make_unique<PluginModel>()}
{}

} // namespace lrc
