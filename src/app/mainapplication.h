/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

#pragma once

#include "lrcinstance.h"
#include "qtutils.h"

#include <QFile>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QScreen>
#include <QWindow>

#include <memory>

class ConnectivityMonitor;
class AppSettingsManager;
class SystemTray;
class PreviewEngine;

// Provides information about the screen the app is displayed on
class ScreenInfo : public QObject
{
    Q_OBJECT
    QML_PROPERTY(double, devicePixelRatio)
public:
    void setCurrentFocusWindow(QWindow* window);

private Q_SLOTS:
    void onScreenChanged();
    void onPhysicalDotsPerInchChanged();

private:
    QWindow* currentFocusWindow_ {nullptr};
    QScreen* currentFocusWindowScreen_ {nullptr};
};

class MainApplication : public QApplication
{
    Q_OBJECT
    Q_DISABLE_COPY(MainApplication)
    QML_RO_PROPERTY(bool, startMinimized)
public:
    explicit MainApplication(int& argc, char** argv);
    ~MainApplication();

    bool init();
    void restoreApp();

    Q_INVOKABLE void handleUriAction(const QString& uri = {});

    enum class Option {
        StartMinimized = 0,
        Debug,
        UpdateUrl,
        MuteDaemon,
        TerminationRequested,
        StartUri
    };
    QVariant getOpt(const Option opt)
    {
        return runOptions_[opt];
    };

    Q_INVOKABLE void setEventFilter();

    bool eventFilter(QObject* object, QEvent* event)
    {
#ifdef Q_OS_MACOS

        if (event->type() == QEvent::ApplicationActivate) {
            restoreApp();
        }

#endif // Q_OS_MACOS

        return QApplication::eventFilter(object, event);
    }

Q_SIGNALS:
    void closeRequested();
    void searchAndSelect(const QString& request);

private:
    void initLrc(const QString& downloadUrl,
                 ConnectivityMonitor* cm,
                 bool debugMode,
                 bool muteDaemon);
    void parseArguments();
    void setApplicationFont();
    void initQmlLayer();
    void initSystray();

private:
    std::map<Option, QVariant> runOptions_;

    // We want to be explicit about the destruction order of these objects
    QScopedPointer<QQmlApplicationEngine> engine_;
    QScopedPointer<LRCInstance> lrcInstance_;

    // These are injected into the QML layer along with our LRCInstance
    ConnectivityMonitor* connectivityMonitor_;
    SystemTray* systemTray_;
    AppSettingsManager* settingsManager_;
    PreviewEngine* previewEngine_;

    ScreenInfo screenInfo_;
};
