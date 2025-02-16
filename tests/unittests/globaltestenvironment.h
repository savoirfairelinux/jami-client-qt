/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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

#include "lrcinstance.h"
#include "appsettingsmanager.h"
#include "connectivitymonitor.h"
#include "systemtray.h"
#include "previewengine.h"
#include "messageparser.h"
#include "accountadapter.h"

#include <QTest>
#include <QSignalSpy>

#include <gtest/gtest.h>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

class TestEnvironment
{
public:
    TestEnvironment() = default;
    ~TestEnvironment() = default;

    void SetUp()
    {
        connectivityMonitor.reset(new ConnectivityMonitor(nullptr));
        settingsManager.reset(new AppSettingsManager(nullptr));
        systemTray.reset(new SystemTray(settingsManager.get(), nullptr));

        std::atomic_bool isMigrating(false);
        lrcInstance.reset(new LRCInstance("", connectivityMonitor.get(), debugMode, muteDaemon));
        lrcInstance->subscribeToDebugReceived();

        // setup the adapters (their lifetimes are that of MainApplication)
        accountAdapter.reset(new AccountAdapter(settingsManager.get(),
                                                systemTray.get(),
                                                lrcInstance.data(),
                                                nullptr));

        previewEngine.reset(new PreviewEngine(connectivityMonitor.get(), nullptr));
        messageParser.reset(new MessageParser(previewEngine.data(), nullptr));
    }

    void TearDown()
    {
        accountAdapter.reset();

        systemTray.reset();
        settingsManager.reset();
        lrcInstance.reset();
        connectivityMonitor.reset();
    }

    bool debugMode {false};
    bool muteDaemon {false};

    QScopedPointer<AccountAdapter> accountAdapter;

    QScopedPointer<LRCInstance> lrcInstance;
    QScopedPointer<ConnectivityMonitor> connectivityMonitor;
    QScopedPointer<AppSettingsManager> settingsManager;
    QScopedPointer<SystemTray> systemTray;
    QScopedPointer<PreviewEngine> previewEngine;
    QScopedPointer<MessageParser> messageParser;
};

extern TestEnvironment globalEnv;
