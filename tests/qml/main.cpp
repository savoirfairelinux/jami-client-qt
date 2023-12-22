/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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

#include "appsettingsmanager.h"
#include "connectivitymonitor.h"
#include "mainapplication.h"
#include "previewengine.h"
#include "qmlregister.h"
#include "systemtray.h"
#include "videoprovider.h"
#include "api/profile.h"
#include "api/account.h"
#include "api/conversationmodel.h"
#include "api/contactmodel.h"

#include <atomic>

#include <QFontDatabase>
#include <QQmlContext>
#include <QQmlEngine>
#include <QScopedPointer>
#include <QtQuickTest/quicktest.h>
#include <QSignalSpy>

#ifdef WITH_WEBENGINE
#include <QtWebEngineCore>
#include <QtWebEngineQuick>
#endif

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include <thread>
using namespace std::literals::chrono_literals;

class Setup : public QObject
{
    Q_OBJECT

public:
    Setup(bool muteDaemon = false)
        : muteDaemon_(muteDaemon)
    {}

    ~Setup()
    {
        QSignalSpy accountRemovedSpy(&lrcInstance_->accountModel(), &AccountModel::accountRemoved);
        lrcInstance_->accountModel().removeAccount(aliceId);
        lrcInstance_->accountModel().removeAccount(bobId);
        while (accountRemovedSpy.count() != 2) {
            accountRemovedSpy.wait();
        }
    }

public Q_SLOTS:

    /*
     * Called once before qmlEngineAvailable.
     */
    void applicationAvailable()
    {
        connectivityMonitor_.reset(new ConnectivityMonitor(this));
        settingsManager_.reset(new AppSettingsManager(this));
        systemTray_.reset(new SystemTray(settingsManager_.get(), this));
        previewEngine_.reset(new PreviewEngine(connectivityMonitor_.get(), this));

        QFontDatabase::addApplicationFont(":/images/FontAwesome.otf");

        lrcInstance_.reset(
            new LRCInstance(nullptr, nullptr, "", connectivityMonitor_.get(), true, muteDaemon_));
        lrcInstance_->subscribeToDebugReceived();

        auto downloadPath = settingsManager_->getValue(Settings::Key::DownloadPath);
        lrcInstance_->accountModel().downloadDirectory = downloadPath.toString() + "/";

        // Create 2 Account
        QSignalSpy accountStatusChangedSpy(&lrcInstance_->accountModel(),
                                        &AccountModel::accountStatusChanged);

        QSignalSpy accountAddedSpy(&lrcInstance_->accountModel(), &AccountModel::accountAdded);
        aliceId = lrcInstance_->accountModel().createNewAccount(profile::Type::JAMI, "Alice");
        accountAddedSpy.wait(15000);
        QCOMPARE(accountAddedSpy.count(), 1);

        bobId = lrcInstance_->accountModel().createNewAccount(profile::Type::JAMI, "Bob");
        accountAddedSpy.wait(15000);
        QCOMPARE(accountAddedSpy.count(), 2);

        // Create a conversation
        auto& aliceInfo = lrcInstance_->accountModel().getAccountInfo(aliceId);
        auto& bobInfo = lrcInstance_->accountModel().getAccountInfo(bobId);
        ConversationModel* bobCM = bobInfo.conversationModel.get();
        QSignalSpy conversationReqSpy(&*bobCM, &ConversationModel::newConversation);
        contact::Info bobContact;
        bobContact.profileInfo.uri = bobInfo.profileInfo.uri;
        bobContact.profileInfo.type = profile::Type::TEMPORARY;
        aliceInfo.contactModel->addContact(bobContact);
        conversationReqSpy.wait(15000);
        QCOMPARE(conversationReqSpy.count(), 1);
    }

    /*
     * Called when the QML engine is available. Any import paths, plugin paths,
     * and extra file selectors will have been set on the engine by this point.
     * This function is called once for each QML test file, so any arguments are
     * unique to that test. For example, this means that each QML test file will
     * have its own QML engine.
     *
     * This function can be used to register QML types and add import paths,
     * amongst other things.
     */
    void qmlEngineAvailable(QQmlEngine* engine)
    {
        lrcInstance_->set_currentAccountId(aliceId);
        auto& aliceInfo = lrcInstance_->accountModel().getAccountInfo(aliceId);
        lrcInstance_->set_selectedConvUid(aliceInfo.conversationModel->getConversations()[0].uid);

        // Expose custom types to the QML engine.
        Utils::registerTypes(engine,
                             lrcInstance_.get(),
                             systemTray_.get(),
                             settingsManager_.get(),
                             connectivityMonitor_.get(),
                             &screenInfo_,
                             this);

        auto videoProvider = new VideoProvider(lrcInstance_->avModel(), this);
        engine->rootContext()->setContextProperty("videoProvider", videoProvider);
#ifdef WITH_WEBENGINE
        engine->rootContext()->setContextProperty("WITH_WEBENGINE", QVariant(true));
#else
        engine->rootContext()->setContextProperty("WITH_WEBENGINE", QVariant(false));
#endif
    }

    /*
     * Called once right after the all test execution has finished. Use this
     * function to clean up before everything is destroyed.
     */
    void cleanupTestCase() {}

private:
    QScopedPointer<LRCInstance> lrcInstance_;

    QScopedPointer<ConnectivityMonitor> connectivityMonitor_;
    QScopedPointer<AppSettingsManager> settingsManager_;
    QScopedPointer<SystemTray> systemTray_;
    QScopedPointer<PreviewEngine> previewEngine_;
    ScreenInfo screenInfo_;

    bool muteDaemon_ {false};
    QString aliceId;
    QString bobId;
};

int
main(int argc, char** argv)
{
    QDir tempDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation));

    auto jamiDataDir = tempDir.absolutePath() + "/jami_test/jami";
    auto jamiConfigDir = tempDir.absolutePath() + "/jami_test/.config";
    auto jamiCacheDir = tempDir.absolutePath() + "/jami_test/.cache";

    // Clean up the temp directories.
    QDir(jamiDataDir).removeRecursively();
    QDir(jamiConfigDir).removeRecursively();
    QDir(jamiCacheDir).removeRecursively();

    bool envSet = qputenv("JAMI_DATA_HOME", jamiDataDir.toLocal8Bit());
    envSet &= qputenv("JAMI_CONFIG_HOME", jamiConfigDir.toLocal8Bit());
    envSet &= qputenv("JAMI_CACHE_HOME", jamiCacheDir.toLocal8Bit());
    if (!envSet)
        return 1;

    bool muteDaemon {false};

    // We likely want to mute the daemon for log clarity.
    Utils::remove_argument(argv, argc, "--mutejamid", [&]() { muteDaemon = true; });

    // Allow the user to enable fatal warnings for certain tests.
    Utils::remove_argument(argv, argc, "--failonwarn", [&]() { qputenv("QT_FATAL_WARNINGS", "1"); });

#ifdef WITH_WEBENGINE
    QtWebEngineQuick::initialize();
#endif
    QTEST_SET_MAIN_SOURCE_PATH
    Setup setup(muteDaemon);
    return quick_test_main_with_setup(argc, argv, "qml_test", nullptr, &setup);
}

#include "main.moc"
