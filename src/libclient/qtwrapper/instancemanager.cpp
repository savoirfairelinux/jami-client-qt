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

#include "instancemanager_wrap.h"
#include "callmanager.h"
#include "presencemanager.h"
#include "configurationmanager.h"
#ifdef ENABLE_VIDEO
#include "videomanager.h"
#endif // ENABLE_VIDEO
#include <QDir>

static int ringFlags = 0;

InstanceManagerInterface::InstanceManagerInterface(bool muteDaemon)
{
    // The following code is used to set the resource directory for libjami, and is required
    // for the ringtones to work properly on platforms where the resource directory path is not
    // fixed (e.g. macOS).
#if defined(Q_OS_WIN)
    // On Windows, the resource directory is set to the application's directory.
    libjami::setResourceDirPath(QCoreApplication::applicationDirPath().toStdString());
#elif defined(Q_OS_MAC)
    // On macOS, the resource directory is set to the application bundle's path + "/Resources".
    // The application bundle's path is the application's directory.
    QDir execDir(qApp->applicationDirPath()); // executable directory points to the app bundle + /Contents/MacOS/
    execDir.cdUp();                           // navigate up to add resources to /Contents
    auto resourceDir = execDir.absolutePath() + QDir::separator() + "Resources";
    libjami::setResourceDirPath(resourceDir.toStdString());
#endif

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
