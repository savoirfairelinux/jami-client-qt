/*
 * Copyright (C) 2015-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "mainapplication.h"

#include "qmlregister.h"
#include "appsettingsmanager.h"
#include "connectivitymonitor.h"
#include "systemtray.h"
#include "previewengine.h"
#include "rendermanager.h"

#include <QAction>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QFontDatabase>
#include <QMenu>
#include <QQmlContext>
#include <QResource>
#include <QTranslator>
#include <QLibraryInfo>

#include <locale.h>
#include <thread>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#ifdef Q_OS_UNIX
#include "globalinstances.h"
#include "dbuserrorhandler.h"
#endif

#if defined _MSC_VER
#include <gnutls/gnutls.h>
#endif

static void
consoleDebug()
{
#ifdef Q_OS_WIN
    AllocConsole();
    SetConsoleCP(CP_UTF8);

    FILE* fpstdout = stdout;
    freopen_s(&fpstdout, "CONOUT$", "w", stdout);
    FILE* fpstderr = stderr;
    freopen_s(&fpstderr, "CONOUT$", "w", stderr);

    COORD coordInfo;
    coordInfo.X = 130;
    coordInfo.Y = 9000;

    SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE), coordInfo);
    SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), ENABLE_QUICK_EDIT_MODE | ENABLE_EXTENDED_FLAGS);
#endif
}

static QString
getDebugFilePath()
{
    QDir logPath(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
    logPath.cdUp();
    return QString(logPath.absolutePath() + "/jami/jami.log");
}

void
ScreenInfo::setCurrentFocusWindow(QWindow* window)
{
    if (window && !currentFocusWindow_) {
        currentFocusWindow_ = window;
        set_devicePixelRatio(currentFocusWindow_->screen()->devicePixelRatio());

        disconnect(devicePixelRatioConnection_);
        disconnect(currentFocusWindowScreenConnection_);

        currentFocusWindowScreenConnection_
            = connect(currentFocusWindow_, &QWindow::screenChanged, [this] {
                  currentFocusWindowScreen_ = currentFocusWindow_->screen();
                  set_devicePixelRatio(currentFocusWindowScreen_->devicePixelRatio());

                  devicePixelRatioConnection_ = connect(
                      currentFocusWindowScreen_, &QScreen::physicalDotsPerInchChanged, [this] {
                          set_devicePixelRatio(currentFocusWindowScreen_->devicePixelRatio());
                      });
              });
    }
}

void
MainApplication::vsConsoleDebug()
{
#ifdef _MSC_VER
    /*
     * Print debug to output window if using VS.
     */
    QObject::connect(&lrcInstance_->behaviorController(),
                     &lrc::api::BehaviorController::debugMessageReceived,
                     [](const QString& message) {
                         OutputDebugStringA((message + "\n").toStdString().c_str());
                     });
#endif
}

void
MainApplication::fileDebug(QFile* debugFile)
{
    QObject::connect(&lrcInstance_->behaviorController(),
                     &lrc::api::BehaviorController::debugMessageReceived,
                     [debugFile](const QString& message) {
                         if (debugFile->open(QIODevice::WriteOnly | QIODevice::Append)) {
                             auto msg = (message + "\n").toStdString();
                             debugFile->write(msg.c_str(), qstrlen(msg.c_str()));
                             debugFile->close();
                         }
                     });
}

MainApplication::MainApplication(int& argc, char** argv)
    : QApplication(argc, argv)
{
    parseArguments();
    QObject::connect(this, &QApplication::aboutToQuit, [this] { cleanup(); });
}

MainApplication::~MainApplication()
{
    engine_.reset();
    lrcInstance_.reset();
}

bool
MainApplication::init()
{
    // This 2-phase initialisation prevents ephemeral instances from
    // performing unnecessary tasks, like initializing the webengine.
    engine_.reset(new QQmlApplicationEngine(this));
    connectivityMonitor_.reset(new ConnectivityMonitor(this));
    settingsManager_.reset(new AppSettingsManager(this));
    systemTray_.reset(new SystemTray(settingsManager_.get(), this));
    previewEngine_.reset(new PreviewEngine(this));

    QObject::connect(settingsManager_.get(),
                     &AppSettingsManager::retranslate,
                     engine_.get(),
                     &QQmlApplicationEngine::retranslate);

    setWindowIcon(QIcon(":/images/jami.ico"));

#ifdef Q_OS_LINUX
    if (!getenv("QT_QPA_PLATFORMTHEME"))
        setenv("QT_QPA_PLATFORMTHEME", "gtk3", true);
#endif

    if (runOptions_[Option::Debug].toBool()) {
        consoleDebug();
    }

    Utils::removeOldVersions();
    settingsManager_->loadTranslations();
    setApplicationFont();

#if defined _MSC_VER
    gnutls_global_init();
#endif

    initLrc(runOptions_[Option::UpdateUrl].toString(),
            connectivityMonitor_.get(),
            runOptions_[Option::Debug].toBool() && !runOptions_[Option::MuteJamid].toBool());

#if defined(Q_OS_UNIX) && !defined(Q_OS_MACOS)
    using namespace Interfaces;
    GlobalInstances::setDBusErrorHandler(std::make_unique<DBusErrorHandler>());
    auto dBusErrorHandlerQObject = dynamic_cast<QObject*>(&GlobalInstances::dBusErrorHandler());
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, DBusErrorHandler, dBusErrorHandlerQObject);
    if ((!lrc::api::Lrc::isConnected()) || (!lrc::api::Lrc::dbusIsValid())) {
        engine_->load(QUrl(QStringLiteral("qrc:/src/DaemonReconnectWindow.qml")));
        exec();

        if ((!lrc::api::Lrc::isConnected()) || (!lrc::api::Lrc::dbusIsValid())) {
            qWarning() << "Can't connect to the daemon via D-Bus.";
            return false;
        } else {
            engine_.reset(new QQmlApplicationEngine());
        }
    }
#endif

    connect(connectivityMonitor_.get(), &ConnectivityMonitor::connectivityChanged, [this] {
        lrcInstance_->connectivityChanged();
    });

    connect(this, &QGuiApplication::focusWindowChanged, [this] {
        screenInfo_.setCurrentFocusWindow(this->focusWindow());
    });

    QObject::connect(
        lrcInstance_.get(),
        &LRCInstance::quitEngineRequested,
        this,
        [this] { engine_->quit(); },
        Qt::DirectConnection);

    if (runOptions_[Option::DebugToFile].toBool()) {
        debugFile_.reset(new QFile(getDebugFilePath()));
        debugFile_->open(QIODevice::WriteOnly | QIODevice::Truncate);
        debugFile_->close();
        fileDebug(debugFile_.get());
    }

    if (runOptions_[Option::DebugToConsole].toBool()) {
        vsConsoleDebug();
    }

    auto downloadPath = settingsManager_->getValue(Settings::Key::DownloadPath);
    auto allowTransferFromUntrusted = settingsManager_->getValue(Settings::Key::AllowFromUntrusted)
                                          .toBool();
    auto allowTransferFromTrusted = settingsManager_->getValue(Settings::Key::AutoAcceptFiles)
                                        .toBool();
    auto acceptTransferBelow = settingsManager_->getValue(Settings::Key::AcceptTransferBelow).toInt();
    lrcInstance_->accountModel().downloadDirectory = downloadPath.toString() + "/";
    lrcInstance_->accountModel().autoTransferFromUntrusted = allowTransferFromUntrusted;
    lrcInstance_->accountModel().autoTransferFromTrusted = allowTransferFromTrusted;
    lrcInstance_->accountModel().autoTransferSizeThreshold = acceptTransferBelow;

    auto startMinimizedSetting = settingsManager_->getValue(Settings::Key::StartMinimized).toBool();
    // The presence of start URI should override the startMinimized setting for this instance.
    set_startMinimized(startMinimizedSetting && runOptions_[Option::StartUri].isNull());

    initQmlLayer();

    settingsManager_->setValue(Settings::Key::StartMinimized,
                               runOptions_[Option::StartMinimized].toBool());

    initSystray();

    return true;
}

void
MainApplication::restoreApp()
{
    Q_EMIT lrcInstance_->restoreAppRequested();
}

void
MainApplication::handleUriAction(const QString& arg)
{
    QString uri {};
    if (arg.isEmpty() && !runOptions_[Option::StartUri].isNull()) {
        uri = runOptions_[Option::StartUri].toString();
        qDebug() << "URI action invoked by run option" << uri;
    } else {
        uri = arg;
        qDebug() << "URI action invoked by secondary instance" << uri;
    }
    // TODO: implement URI protocol handling.
}

void
MainApplication::initLrc(const QString& downloadUrl, ConnectivityMonitor* cm, bool logDaemon)
{
    lrc::api::Lrc::cacheAvatars.store(false);
    /*
     * Init mainwindow and finish splash when mainwindow shows up.
     */
    std::atomic_bool isMigrating(false);
    lrcInstance_.reset(new LRCInstance(
        [this, &isMigrating] {
            /*
             * TODO: splash screen for account migration.
             */
            isMigrating = true;
            while (isMigrating) {
                this->processEvents();
            }
        },
        [&isMigrating] {
            while (!isMigrating) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
            isMigrating = false;
        },
        downloadUrl,
        cm,
        !logDaemon));
    lrcInstance_->subscribeToDebugReceived();
}

void
MainApplication::parseArguments()
{
    // See if the app is being started with a URI.
    for (const auto& arg : QApplication::arguments()) {
        if (arg.startsWith("jami:")) {
            runOptions_[Option::StartUri] = arg;
        }
    }

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();

    // These options are potentially forced into the arg list.
    QCommandLineOption webSecurityDisableOption(QStringList() << "disable-web-security");
    parser.addOption(webSecurityDisableOption);

    QCommandLineOption noSandboxOption(QStringList() << "no-sandbox");
    parser.addOption(noSandboxOption);

    QCommandLineOption singleProcessOption(QStringList() << "single-process");
    parser.addOption(singleProcessOption);

    QCommandLineOption webDebugOption(QStringList() << "remote-debugging-port",
                                      "Web debugging port.",
                                      "port");
    parser.addOption(webDebugOption);

    QCommandLineOption minimizedOption({"m", "minimized"}, "Start minimized.");
    parser.addOption(minimizedOption);

    QCommandLineOption debugOption({"d", "debug"}, "Debug out.");
    parser.addOption(debugOption);

    QCommandLineOption debugFileOption({"f", "file"}, "Debug to file.");
    parser.addOption(debugFileOption);

#ifdef Q_OS_WINDOWS
    QCommandLineOption debugConsoleOption({"c", "console"}, "Debug out to IDE console.");
    parser.addOption(debugConsoleOption);

    QCommandLineOption updateUrlOption({"u", "url"}, "<url> for debugging version queries.", "url");
    parser.addOption(updateUrlOption);

#endif
    QCommandLineOption terminateOption({"t", "term"}, "Terminate all instances.");
    parser.addOption(terminateOption);

    QCommandLineOption muteDaemonOption({"q", "quiet"}, "Mute daemon logging. (only if debug)");
    parser.addOption(muteDaemonOption);

    parser.process(*this);

    runOptions_[Option::StartMinimized] = parser.isSet(minimizedOption);
    runOptions_[Option::Debug] = parser.isSet(debugOption);
    runOptions_[Option::DebugToFile] = parser.isSet(debugFileOption);
#ifdef Q_OS_WINDOWS
    runOptions_[Option::DebugToConsole] = parser.isSet(debugConsoleOption);
    runOptions_[Option::UpdateUrl] = parser.value(updateUrlOption);
#endif
    runOptions_[Option::TerminationRequested] = parser.isSet(terminateOption);
    runOptions_[Option::MuteJamid] = parser.isSet(muteDaemonOption);
}

void
MainApplication::setApplicationFont()
{
    QFont font;
    font.setFamily("Segoe UI");
    setFont(font);
    QFontDatabase::addApplicationFont(":/fonts/FontAwesome.otf");
}

void
MainApplication::initQmlLayer()
{
    // Expose custom types to the QML engine.
    Utils::registerTypes(engine_.get(),
                         systemTray_.get(),
                         lrcInstance_.get(),
                         settingsManager_.get(),
                         previewEngine_.get(),
                         &screenInfo_,
                         this);

    auto videoProvider = new VideoProvider(lrcInstance_->avModel(), this);
    QQmlContext* context = engine_->rootContext();
    context->setContextProperty("videoProvider", videoProvider);

    engine_->load(QUrl(QStringLiteral("qrc:/src/MainApplicationWindow.qml")));
}

void
MainApplication::initSystray()
{
    systemTray_->setIcon(QIcon(":/images/jami.svg"));

    QMenu* systrayMenu = new QMenu();

    QString quitString;
#ifdef Q_OS_WINDOWS
    quitString = tr("E&xit");
#else
    quitString = tr("&Quit");
#endif

    QAction* quitAction = new QAction(quitString, this);
    connect(quitAction, &QAction::triggered, this, &MainApplication::closeRequested);

    QAction* restoreAction = new QAction(tr("&Show Jami"), this);
    connect(restoreAction, &QAction::triggered, this, &MainApplication::restoreApp);

    connect(systemTray_.get(),
            &QSystemTrayIcon::activated,
            this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                if (reason != QSystemTrayIcon::ActivationReason::Context) {
#ifdef Q_OS_WINDOWS
                    restoreApp();
#else
                    QWindow* window = focusWindow();
                    if (window)
                        window->close();
                    else
                        restoreApp();
#endif
                }
            });

    systrayMenu->addAction(restoreAction);
    systrayMenu->addAction(quitAction);
    systemTray_->setContextMenu(systrayMenu);
    systemTray_->show();
}

void
MainApplication::cleanup()
{
#ifdef Q_OS_WIN
    FreeConsole();
#endif
    QApplication::exit(0);
}
