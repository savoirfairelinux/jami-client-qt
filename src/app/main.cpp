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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "mainapplication.h"
#include "instancemanager.h"
#include "webengineutils.h"
#include "version_info.h"
#if defined(Q_OS_MACOS)
#include <os/macos/macutils.h>
#endif

#include <QApplication>
#include <QCryptographicHash>
#include <QtQuick>
#if WITH_WEBENGINE
#include <QtWebEngineCore>
#include <QtWebEngineQuick>
#endif
#if defined(HAS_VULKAN) && !defined(Q_OS_LINUX)
#include <QVulkanInstance>
#endif

#include <clocale>

#ifndef BUILD_TESTING
int
main(int argc, char* argv[])
{
    setlocale(LC_ALL, "en_US.utf8");
    // DEBUG Uncomment this to visualize overdraw in the renderer
    // qputenv("QSG_VISUALIZE", "overdraw");

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

    QApplication::setApplicationName(QStringLiteral("Jami"));
    QApplication::setOrganizationDomain(QStringLiteral("jami.net"));
    QApplication::setQuitOnLastWindowClosed(false);
    QCoreApplication::setApplicationVersion(BUILD_VERSION_STRING);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts, true);
    QApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

#if WITH_WEBENGINE
    if (Utils::isWebEngineRuntimeAvailable()) {
        // Preserve any user-provided QTWEBENGINE_CHROMIUM_FLAGS instead of
        // overwriting them, so the GPU behaviour can still be overridden from the
        // environment.
        //
        // --single-process is intentional: it avoids spawning a QtWebEngineProcess
        // per message webview in a busy chat. A consequence is that Chromium's GPU
        // runs in-process, so a GPU crash is fatal to the whole app.
        //
        // --disable-gpu works around a Qt 6.10 QtWebEngine crash: on some configs
        // (e.g. NVIDIA on native Wayland) Chromium logs "GBM is not supported ...
        // Fallback to Vulkan rendering in Chromium" and then intermittently crashes
        // in its in-process Vulkan GPU. Disabling the Chromium GPU only affects web
        // content rendering (emoji picker, message/map webviews); the Qt Quick scene
        // graph keeps its own GPU acceleration. Nothing narrower removes the Vulkan
        // fallback (--disable-vulkan, --disable-features=Vulkan, --use-gl=*,
        // QSG_RHI_BACKEND=opengl were all verified ineffective).
        QByteArray chromiumFlags = qgetenv("QTWEBENGINE_CHROMIUM_FLAGS");
        if (!chromiumFlags.isEmpty())
            chromiumFlags.append(' ');
        chromiumFlags.append("--disable-web-security --single-process --disable-gpu");
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags);
        QtWebEngineQuick::initialize();
    } else {
        qWarning() << "Qt WebEngine is disabled on this operating system.";
    }
#endif

    MainApplication app(argc, argv);

    app.setDesktopFileName(QStringLiteral("net.jami.Jami"));
#if defined(Q_OS_MACOS)
    if (macutils::isMetalSupported()) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::MetalRhi);
    } else {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGLRhi);
    }
#else
    if (std::invoke([] {
#if defined(HAS_VULKAN) && defined(PREFER_VULKAN)
            // Somehow, several bug reports show that, on Windows, QVulkanInstance
            // verification  passes, but goes on to fail when creating the QQuickWindow
            // with "Failed to initialize graphics backend for Vulkan".
            // Here we allow platform-specific checks using native Vulkan libraries.
            // Currently only implemented on Windows.
            try {
                Utils::testVulkanSupport();
            } catch (const std::exception& e) {
                qWarning() << "Vulkan instance cannot be created:" << e.what();
                return false;
            }

            // Check using Qt's QVulkanInstance.
            QVulkanInstance inst;
            return inst.supportedLayers().contains("VK_LAYER_KHRONOS_validation");
#else
            return false;
#endif
        })
        && qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        // https://bugreports.qt.io/browse/QTBUG-99684 - Vulkan on
        // Wayland is not really supported as window decorations are
        // removed. So we need to re-implement this (custom controls)
        // or wait for a future version
        QQuickWindow::setGraphicsApi(QSGRendererInterface::VulkanRhi);
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
