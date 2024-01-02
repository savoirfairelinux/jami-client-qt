/****************************************************************************
 *    Copyright (C) 2009-2024 Savoir-faire Linux Inc.                       *
 *   Authors : Alexandre Lision alexandre.lision@savoirfairelinux.com       *
 *   Author : Alexandre Lision <alexandre.lision@savoirfairelinux.com>      *
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

#include "instancemanager_wrap.h"
#include "callmanager.h"
#include "presencemanager.h"
#include "configurationmanager.h"
#ifdef ENABLE_VIDEO
#include "videomanager.h"
#endif // ENABLE_VIDEO

static int ringFlags = 0;

InstanceManagerInterface::InstanceManagerInterface(bool muteDaemon)
{
    using namespace std::placeholders;

    using std::bind;
    using libjami::exportable_callback;
    using libjami::CallSignal;
    using libjami::ConfigurationSignal;
    using libjami::PresenceSignal;
    using libjami::DataTransferSignal;
    using libjami::ConversationSignal;

#ifdef ENABLE_VIDEO
    using libjami::VideoSignal;
    using libjami::MediaPlayerSignal;
#endif

#ifndef MUTE_LIBJAMI
    if (!muteDaemon) {
        ringFlags |= libjami::LIBJAMI_FLAG_DEBUG;
        ringFlags |= libjami::LIBJAMI_FLAG_CONSOLE_LOG;
    }
#endif

    libjami::init(static_cast<libjami::InitFlag>(ringFlags));

    registerSignalHandlers(CallManager::instance().callHandlers);
    registerSignalHandlers(ConfigurationManager::instance().confHandlers);
    registerSignalHandlers(PresenceManager::instance().presHandlers);
    registerSignalHandlers(ConfigurationManager::instance().dataXferHandlers);
#ifdef ENABLE_VIDEO
    registerSignalHandlers(VideoManager::instance().videoHandlers);
#endif
    registerSignalHandlers(ConfigurationManager::instance().conversationsHandlers);

    if (!libjami::start())
        printf("Error initializing daemon\n");
    else
        printf("Daemon is running\n");
}

InstanceManagerInterface::~InstanceManagerInterface() {}

bool
InstanceManagerInterface::isConnected()
{
    return true;
}
