/*
 * Copyright (C) 2015-2024 Savoir-faire Linux Inc.
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

#include <QWKQuick/qwkquickglobal.h>

#include <QAction>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QFontDatabase>
#include <QMenu>
#include <QQmlContext>
#include <QResource>
#include <QTimer>
#include <QTranslator>
#include <QLibraryInfo>
#include <QQuickWindow>
#include <QLoggingCategory>

#include <thread>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#ifdef Q_OS_UNIX
#include "globalinstances.h"
#include "dbuserrorhandler.h"
#endif

Q_LOGGING_CATEGORY(app_, "app_")

static const QtMessageHandler QT_DEFAULT_MESSAGE_HANDLER = qInstallMessageHandler(0);

void
messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    const static std::string fmt[5] = {"DBG", "WRN", "CRT", "FTL", "INF"};
    const QByteArray localMsg = msg.toUtf8();
    const auto ts = QString::number(QDateTime::currentMSecsSinceEpoch());

    QString fileLineInfo = "";
#ifdef QT_DEBUG
    // In debug mode, always include file and line info.
    fileLineInfo = QString("[%1:%2]").arg(context.file ? context.file : "unknown",
                                          context.line ? QString::number(context.line) : "0");
#else
    // In release mode, include file and line info only for QML category which will always
    // be available and provide a link to the source code in QtCreator.
    if (QString(context.category) == QLatin1String("qml")) {
        fileLineInfo = QString("[%1:%2]").arg(context.file ? context.file : "unknown",
                                              context.line ? QString::number(context.line) : "0");
    }
#endif

    const auto fmtMsg = QString("[%1][%2]%3: %4")
                            .arg(ts, fmt[type].c_str(), fileLineInfo, localMsg.constData());

    (*QT_DEFAULT_MESSAGE_HANDLER)(type, context, fmtMsg);
}

static QString
getRenderInterfaceString()
{
    using GAPI = QSGRendererInterface::GraphicsApi;
    switch (QQuickWindow::graphicsApi()) {
    case GAPI::Direct3D11Rhi:
        return "Direct3D11Rhi";
    case GAPI::MetalRhi:
        return "MetalRhi";
    case GAPI::OpenGLRhi:
        return "OpenGLRhi";
    case GAPI::VulkanRhi:
        return "VulkanRhi";
    default:
        break;
    }
    return {};
}

void
ScreenInfo::setCurrentFocusWindow(QWindow* window)
{
    if (window && !currentFocusWindow_) {
        currentFocusWindow_ = window;
        set_devicePixelRatio(currentFocusWindow_->screen()->devicePixelRatio());

        QObject::connect(currentFocusWindow_,
                         &QWindow::screenChanged,
                         this,
                         &ScreenInfo::onScreenChanged,
                         Qt::UniqueConnection);
    }
}

void
ScreenInfo::onScreenChanged()
{
    currentFocusWindowScreen_ = currentFocusWindow_->screen();
    set_devicePixelRatio(currentFocusWindowScreen_->devicePixelRatio());

    QObject::connect(currentFocusWindowScreen_,
                     &QScreen::physicalDotsPerInchChanged,
                     this,
                     &ScreenInfo::onPhysicalDotsPerInchChanged,
                     Qt::UniqueConnection);
}

void
ScreenInfo::onPhysicalDotsPerInchChanged()
{
    set_devicePixelRatio(currentFocusWindowScreen_->devicePixelRatio());
}

MainApplication::MainApplication(int& argc, char** argv)
    : QApplication(argc, argv)
{
    const char* qtVersion = qVersion();
    if (strncmp(qtVersion, QT_VERSION_STR, strnlen(qtVersion, sizeof qtVersion)) != 0) {
        qCFatal(app_) << "Qt build version mismatch!" << QT_VERSION_STR;
    }

    parseArguments();

    // Adjust the log levels as needed (as logging categories are added).
    // Note: the following will cause detailed Qt logging and effectively spam the console
    // without using `qt.*=false`. It may be useful for debugging Qt/QtQuick issues.
    QLoggingCategory::setFilterRules("\n"
                                     "*.debug=true\n"
                                     "qt.*=false\n"
                                     "qml.debug=false\n"
                                     "\n");
    // These can be set in the environment as well.
    // e.g. QT_LOGGING_RULES="*.debug=false;qml.debug=true"

    // Tab align the log messages.
    qSetMessagePattern("%{category}\t%{message}");

    // Registration is done late here contrary to suggested practice in order to
    // allow for the arguments to be parsed first in case we want to influence
    // the logging features.
    qInstallMessageHandler(messageHandler);

    qCInfo(app_) << "Using Qt runtime version:" << qtVersion;
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

    QWK::registerTypes(engine_.get());

    connectivityMonitor_ = new ConnectivityMonitor(this);
    settingsManager_ = new AppSettingsManager(this);
    systemTray_ = new SystemTray(settingsManager_, this);
    previewEngine_ = new PreviewEngine(connectivityMonitor_, this);

    // These should should be QueuedConnection to ensure that the
    // they are executed after the QML engine has been initialized,
    // and after the QSystemTrayIcon has been created and shown.
    QObject::connect(settingsManager_,
                     &AppSettingsManager::retranslate,
                     engine_.get(),
                     &QQmlApplicationEngine::retranslate,
                     Qt::QueuedConnection);
    QObject::connect(settingsManager_,
                     &AppSettingsManager::retranslate,
                     this,
                     &MainApplication::initSystray,
                     Qt::QueuedConnection);

    setWindowIcon(QIcon(":/images/jami.ico"));

    Utils::removeOldVersions();
    qputenv("JAMI_LANG", settingsManager_->getLanguage().toUtf8());
    settingsManager_->loadTranslations();
    setApplicationFont();

    initLrc(runOptions_[Option::UpdateUrl].toString(),
            connectivityMonitor_,
            runOptions_[Option::Debug].toBool(),
            runOptions_[Option::MuteDaemon].toBool());

#if defined(Q_OS_UNIX) && !defined(Q_OS_MACOS)
    using namespace Interfaces;
    GlobalInstances::setDBusErrorHandler(std::make_unique<DBusErrorHandler>());
    auto dBusErrorHandlerQObject = dynamic_cast<QObject*>(&GlobalInstances::dBusErrorHandler());
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, DBusErrorHandler, dBusErrorHandlerQObject);
    if ((!lrc::api::Lrc::isConnected()) || (!lrc::api::Lrc::dbusIsValid())) {
        engine_->load(QUrl(QStringLiteral("qrc:/DaemonReconnectWindow.qml")));
        exec();

        if ((!lrc::api::Lrc::isConnected()) || (!lrc::api::Lrc::dbusIsValid())) {
            qWarning() << "Can't connect to the daemon via D-Bus.";
            return false;
        } else {
            engine_.reset(new QQmlApplicationEngine());
        }
    }
#endif

    connect(connectivityMonitor_, &ConnectivityMonitor::connectivityChanged, this, [this] {
        QTimer::singleShot(500, this, [&]() { lrcInstance_->connectivityChanged(); });
    });

    connect(this, &QGuiApplication::focusWindowChanged, [this] {
        screenInfo_.setCurrentFocusWindow(this->focusWindow());
    });

    auto downloadPath = settingsManager_->getValue(Settings::Key::DownloadPath);
    auto screenshotPath = settingsManager_->getValue(Settings::Key::ScreenshotPath);
    auto allowTransferFromTrusted = settingsManager_->getValue(Settings::Key::AutoAcceptFiles)
                                        .toBool();
    auto acceptTransferBelow = settingsManager_->getValue(Settings::Key::AcceptTransferBelow).toInt();
    lrcInstance_->accountModel().downloadDirectory = downloadPath.toString() + "/";
    lrcInstance_->accountModel().screenshotDirectory = screenshotPath.toString();
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
        qCDebug(app_) << "URI action invoked by run option" << uri;
    } else if (!arg.isEmpty()) {
        uri = arg;
        qCDebug(app_) << "URI action invoked by secondary instance" << uri;
        Q_EMIT searchAndSelect(uri.replace("jami:", ""));
    }
}

void
MainApplication::initLrc(const QString& downloadUrl,
                         ConnectivityMonitor* cm,
                         bool debugMode,
                         bool muteDaemon)
{
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
        debugMode,
        muteDaemon));
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

    QCommandLineOption webDebugOption(QStringList() << "remote-debugging-port",
                                      "Web debugging port.",
                                      "port");
    parser.addOption(webDebugOption);

    QCommandLineOption minimizedOption({"m", "minimized"}, "Start minimized.");
    parser.addOption(minimizedOption);

    QCommandLineOption debugOption({"d", "debug"}, "Debug out.");
    parser.addOption(debugOption);

    QCommandLineOption logFileOption({"f", "file"}, "Debug to <file>.", "file");
    parser.addOption(logFileOption);

#ifdef Q_OS_WINDOWS
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
    if (parser.isSet(logFileOption)) {
        auto logFileValue = parser.value(logFileOption);
        auto logFile = logFileValue.isEmpty() ? Utils::getDebugFilePath() : logFileValue;
        qputenv("JAMI_LOG_FILE", logFile.toStdString().c_str());
    }
#ifdef Q_OS_WINDOWS
    runOptions_[Option::UpdateUrl] = parser.value(updateUrlOption);
#endif
    runOptions_[Option::TerminationRequested] = parser.isSet(terminateOption);
    runOptions_[Option::MuteDaemon] = parser.isSet(muteDaemonOption);
}

void
MainApplication::setApplicationFont()
{
    QStringList fontFamilies {"Ubuntu"};
#ifdef Q_OS_LINUX
    QFontDatabase::addApplicationFont(":/fonts/NotoColorEmoji.ttf");
    fontFamilies += "NotoColorEmoji";
#endif
    QFont font;
    font.setFamilies(fontFamilies);
    setFont(font);
}

void
MainApplication::initQmlLayer()
{
    // Expose custom types to the QML engine.
    Utils::registerTypes(engine_.get(),
                         lrcInstance_.get(),
                         systemTray_,
                         settingsManager_,
                         connectivityMonitor_,
                         previewEngine_,
                         &screenInfo_,
                         this);

    engine_->load(QUrl(QStringLiteral("qrc:/MainApplicationWindow.qml")));

    // Report the render interface used.
    qCWarning(app_) << "Main window loaded using" << getRenderInterfaceString();
}

void
MainApplication::initSystray()
{
    systemTray_->setIcon(QIcon(":/images/jami.svg"));

    QMenu* menu {nullptr};
    // If there was a previous menu, reuse it, otherwise create a new one.
    if ((menu = systemTray_->contextMenu())) {
        menu->clear();
    } else {
        menu = new QMenu;
    }

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

    connect(systemTray_,
            &QSystemTrayIcon::activated,
            this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                if (reason != QSystemTrayIcon::ActivationReason::Context) {
#ifdef Q_OS_WINDOWS
                    restoreApp();
#elif !defined(Q_OS_MACOS)
                    QWindow* window = focusWindow();
                    if (window)
                        window->close();
                    else
                        restoreApp();
#endif
                }
            });

    menu->addAction(restoreAction);
    menu->addAction(quitAction);
    systemTray_->setContextMenu(menu);

    systemTray_->show();
}

void
MainApplication::setEventFilter()
{
    installEventFilter(this);
}
