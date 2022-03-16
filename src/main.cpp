/*
 * Copyright (C) 2015-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#include "mainapplication.h"
#include "instancemanager.h"
#include "version.h"

#include <QCryptographicHash>
#include <QApplication>
#include <QtWebEngineCore>
#include <QtWebEngineQuick>
#if defined(HAS_VULKAN)
#include <QVulkanInstance>
#endif

#include <clocale>

#ifndef ENABLE_TESTS

static char**
parseInputArgument(int& argc, char* argv[], QList<char*> argsToParse)
{
    /*
     * Forcefully append argsToParse.
     */
    int oldArgc = argc;
    argc += argsToParse.size();
    auto newArgv = new char*[argc];
    for (int i = 0; i < oldArgc; i++) {
        newArgv[i] = argv[i];
    }

    for (int i = oldArgc; i < argc; i++) {
        newArgv[i] = argsToParse.at(i - oldArgc);
    }
    return newArgv;
}

// Qt WebEngine Chromium Flags
static char disableWebSecurity[] {"--disable-web-security"};
static char singleProcess[] {"--single-process"};

int
main(int argc, char* argv[])
{
    setlocale(LC_ALL, "en_US.utf8");

    QList<char*> qtWebEngineChromiumFlags;

#ifdef Q_OS_LINUX
    if (!getenv("QT_QPA_PLATFORMTHEME")) {
        auto xdgEnv = qgetenv("XDG_CURRENT_DESKTOP");
        if (xdgEnv != "KDE" && xdgEnv != "GNOME") {
            setenv("QT_QPA_PLATFORMTHEME", "gtk3", true);
        }
    }
    setenv("QML_DISABLE_DISK_CACHE", "1", true);

    /*
     * Some GNU/Linux distros, like Zorin OS, set QT_STYLE_OVERRIDE
     * to force a particular Qt style.  This has been fine with Qt5
     * even when using our own Qt package which may not have that
     * style available.  However, with Qt6, attempting to override
     * to a nonexistent style seems to result in the main window
     * simply not showing.  So here we unset this variable, also
     * because we currently hard-code the Material style anyway.
     * https://bugreports.qt.io/browse/QTBUG-99889
     */
    unsetenv("QT_STYLE_OVERRIDE");
#endif
    qtWebEngineChromiumFlags << disableWebSecurity;
    qtWebEngineChromiumFlags << singleProcess;

    QApplication::setApplicationName("Jami");
    QApplication::setOrganizationDomain("jami.net");
    QApplication::setQuitOnLastWindowClosed(false);
    QCoreApplication::setApplicationVersion(QString(VERSION_STRING));
    QApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    auto newArgv = parseInputArgument(argc, argv, qtWebEngineChromiumFlags);

    MainApplication app(argc, newArgv);

#if defined(Q_OS_MACOS)
    QQuickWindow::setGraphicsApi(QSGRendererInterface::MetalRhi);
#else
    if (std::invoke([] {
#if defined(HAS_VULKAN)
            QVulkanInstance inst;
            inst.setLayers({"VK_LAYER_KHRONOS_validation"});
            return inst.create();
#else
            return false;
#endif
        })
        && qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        // https://bugreports.qt.io/browse/QTBUG-99684 - Vulkan on
        // Wayland is not really supported as window decorations are
        // removed. So we need to re-implement this (custom controls)
        // or wait for a future version
        QQuickWindow::setGraphicsApi(QSGRendererInterface::VulkanRhi);
    } else {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Unknown);
    }
#endif

    // InstanceManager prevents multiple instances, and will handle
    // IPC termination requests to and from secondary instances, which
    // is used to gracefully terminate the app from an installer script
    // during an update.
    InstanceManager im(&app);
    if (app.getOpt(MainApplication::Option::TerminationRequested).toBool()) {
        qWarning() << "Attempting to terminate other instances.";
        im.tryToKill();
        return 0;
    } else {
        auto startUri = app.getOpt(MainApplication::Option::StartUri);
        if (!im.tryToRun(startUri.toByteArray())) {
            qWarning() << "Another instance is running.";
            return 0;
        }
    }

    if (!app.init()) {
        return 0;
    }

    return app.exec();
}
#endif
