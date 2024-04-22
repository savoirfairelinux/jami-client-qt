/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "qmlregister.h"

#include "accountadapter.h"
#include "avadapter.h"
#include "calladapter.h"
#include "contactadapter.h"
#include "pluginadapter.h"
#include "messagesadapter.h"
#include "positionmanager.h"
#include "tipsmodel.h"
#include "connectivitymonitor.h"
#include "filedownloader.h"
#include "utilsadapter.h"
#include "conversationsadapter.h"
#include "currentcall.h"
#include "currentconversation.h"
#include "currentaccount.h"
#include "videodevices.h"
#include "currentaccounttomigrate.h"
#include "pttlistener.h"
#include "calloverlaymodel.h"
#include "accountlistmodel.h"
#include "mediacodeclistmodel.h"
#include "audiodevicemodel.h"
#include "audiomanagerlistmodel.h"
#include "bannedlistmodel.h"
#include "moderatorlistmodel.h"
#include "deviceitemlistmodel.h"
#include "smartlistmodel.h"
#include "filestosendlistmodel.h"
#include "callInformationListModel.h"
#include "connectioninfolistmodel.h"
#include "callparticipantsmodel.h"
#include "pluginlistmodel.h"
#include "pluginstorelistmodel.h"
#include "videoprovider.h"
#include "qrimageprovider.h"
#include "avatarimageprovider.h"
#include "avatarregistry.h"
#include "appsettingsmanager.h"
#include "mainapplication.h"
#include "namedirectory.h"
#include "pluginversionmanager.h"
#include "appversionmanager.h"
#include "pluginlistpreferencemodel.h"
#include "preferenceitemlistmodel.h"
#include "wizardviewstepmodel.h"
#include "spellchecker.h"

#include "api/peerdiscoverymodel.h"
#include "api/codecmodel.h"
#include "api/devicemodel.h"
#include "api/datatransfermodel.h"
#include "api/pluginmodel.h"
#include "api/conversation.h"
#include "api/callparticipantsmodel.h"

#include <QMetaType>
#include <QQmlEngine>
#include <QQmlContext>

// clang-format off
// TODO: remove this
#define QML_REGISTERSINGLETONTYPE_WITH_INSTANCE(T) \
    QQmlEngine::setObjectOwnership(&T::instance(), QQmlEngine::CppOwnership); \
    qmlRegisterSingletonType<T>(NS_MODELS, MODULE_VER_MAJ, MODULE_VER_MIN, #T, \
                                [](QQmlEngine* e, QJSEngine* se) -> QObject* { \
                                    Q_UNUSED(e); Q_UNUSED(se); \
                                    return &(T::instance()); \
                                });

#define QML_REGISTERSINGLETONTYPE_URL(NS, URL, T) \
    qmlRegisterSingletonType(QUrl(QStringLiteral(URL)), NS, MODULE_VER_MAJ, MODULE_VER_MIN, #T);

#define QML_REGISTERTYPE(NS, T) qmlRegisterType<T>(NS, MODULE_VER_MAJ, MODULE_VER_MIN, #T);

#define QML_REGISTERNAMESPACE(NS, T, NAME) \
    qmlRegisterUncreatableMetaObject(T, NS, MODULE_VER_MAJ, MODULE_VER_MIN, NAME, "")

#define QML_REGISTERUNCREATABLE(N, T) \
    qmlRegisterUncreatableType<T>(N, MODULE_VER_MAJ, MODULE_VER_MIN, #T, "Don't try to add to a qml definition of " #T);

#define QML_REGISTERUNCREATABLE_IN_NAMESPACE(T, NAMESPACE) \
    qmlRegisterUncreatableType<NAMESPACE::T>(NS_MODELS, \
                                             MODULE_VER_MAJ, MODULE_VER_MIN, #T, \
                                             "Don't try to add to a qml definition of " #T);

#define REG_QML_SINGLETON qmlRegisterSingletonType
#define REG_MODEL NS_MODELS, MODULE_VER_MAJ, MODULE_VER_MIN
#define CREATE(Obj) [=](QQmlEngine*, QJSEngine*) -> QObject* { return Obj; }

namespace Utils {

/*!
 * This function will expose custom types to the QML engine.
 */
void
registerTypes(QQmlEngine* engine,
              LRCInstance* lrcInstance,
              SystemTray* systemTray,
              AppSettingsManager* settingsManager,
              ConnectivityMonitor* connectivityMonitor,
              PreviewEngine* previewEngine,
              ScreenInfo* screenInfo,
              QObject* app)
{
    /* Used in ContactAdapter */
    auto connectionInfoListModel = new ConnectionInfoListModel(lrcInstance, app);
    qApp->setProperty("ConnectionInfoListModel", QVariant::fromValue(connectionInfoListModel));
    QQmlEngine::setObjectOwnership(connectionInfoListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<ConnectionInfoListModel>(REG_MODEL, "ConnectionInfoListModel", CREATE(connectionInfoListModel));

    /* Used in AccountAdapter */
    auto accountListModel = new AccountListModel(lrcInstance, app);
    qApp->setProperty("AccountListModel", QVariant::fromValue(accountListModel));
    QQmlEngine::setObjectOwnership(accountListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<AccountListModel>(REG_MODEL, "AccountListModel", CREATE(accountListModel));

    auto deviceItemListModel = new DeviceItemListModel(lrcInstance, app);
    qApp->setProperty("DeviceItemListModel", QVariant::fromValue(deviceItemListModel));
    QQmlEngine::setObjectOwnership(deviceItemListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<DeviceItemListModel>(REG_MODEL, "DeviceItemListModel", CREATE(deviceItemListModel));

    auto moderatorListModel = new ModeratorListModel(lrcInstance, app);
    qApp->setProperty("ModeratorListModel", QVariant::fromValue(moderatorListModel));
    QQmlEngine::setObjectOwnership(moderatorListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<ModeratorListModel>(REG_MODEL, "ModeratorListModel", CREATE(moderatorListModel));

    /* Used in CallAdapter */
    auto pttListener = new PTTListener(settingsManager, app);
    qApp->setProperty("PTTListener", QVariant::fromValue(pttListener));
    QQmlEngine::setObjectOwnership(pttListener, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<PTTListener>(REG_MODEL, "PTTListener", CREATE(pttListener));

    auto callOverlayModel = new CallOverlayModel(lrcInstance, pttListener, app);
    qApp->setProperty("CallOverlayModel", QVariant::fromValue(callOverlayModel));
    QQmlEngine::setObjectOwnership(callOverlayModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<CallOverlayModel>(REG_MODEL, "CallOverlayModel", CREATE(callOverlayModel));

    /* Used in CurrentCall */
    auto callParticipantsModel = new CallParticipantsModel(lrcInstance, app);
    qApp->setProperty("CallParticipantsModel", QVariant::fromValue(callParticipantsModel));
    QQmlEngine::setObjectOwnership(callParticipantsModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<CallParticipantsModel>(REG_MODEL, "CallParticipantsModel", CREATE(callParticipantsModel));

    /* Used in ConversationsAdapter */
    auto convListProxyModel = new ConversationListProxyModel(nullptr, app);
    qApp->setProperty("ConvListProxyModel", QVariant::fromValue(convListProxyModel));
    auto searchProxyListModel = new SelectableListProxyModel(nullptr, app);
    qApp->setProperty("ConvSearchListProxyModel", QVariant::fromValue(searchProxyListModel));

    // This causes mutually exclusive selection between the two proxy models.
    new SelectableListProxyGroupModel({convListProxyModel, searchProxyListModel}, app);

    /* Used in PluginManager */
    auto pluginListModel = new PluginListModel(lrcInstance, app);
    qApp->setProperty("PluginListModel", QVariant::fromValue(pluginListModel));
    QQmlEngine::setObjectOwnership(pluginListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<PluginListModel>(REG_MODEL, "PluginListModel", CREATE(pluginListModel));

    auto pluginStoreListModel = new PluginStoreListModel(lrcInstance, app);
    qApp->setProperty("PluginStoreListModel", QVariant::fromValue(pluginStoreListModel));
    QQmlEngine::setObjectOwnership(pluginStoreListModel, QQmlEngine::CppOwnership);
    REG_QML_SINGLETON<PluginStoreListModel>(REG_MODEL, "PluginStoreListModel", CREATE(pluginStoreListModel));

    // Register app-level objects that are used by QML created objects.
    // These MUST be set prior to loading the initial QML file, in order to
    // be available to the QML adapter class factory creation methods.
    qApp->setProperty("LRCInstance", QVariant::fromValue(lrcInstance));
    qApp->setProperty("SystemTray", QVariant::fromValue(systemTray));
    qApp->setProperty("AppSettingsManager", QVariant::fromValue(settingsManager));
    qApp->setProperty("ConnectivityMonitor", QVariant::fromValue(connectivityMonitor));
    qApp->setProperty("PreviewEngine", QVariant::fromValue(previewEngine));

    // qml adapter registration
    QML_REGISTERSINGLETON_TYPE(NS_HELPERS, AvatarRegistry);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, AccountAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, CallAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, MessagesAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, ConversationsAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, ContactAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, UtilsAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, PositionManager);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, AvAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, PluginAdapter);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, CurrentAccount);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, CurrentConversation);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, CurrentCall);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, TipsModel);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, VideoDevices);
    QML_REGISTERSINGLETON_TYPE(NS_ADAPTERS, CurrentAccountToMigrate);
    QML_REGISTERSINGLETON_TYPE(NS_MODELS, WizardViewStepModel);
    QML_REGISTERSINGLETON_TYPE(NS_HELPERS, FileDownloader);

    // TODO: remove these
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, AVModel, &lrcInstance->avModel())
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, PluginModel, &lrcInstance->pluginModel())
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_HELPERS, AppVersionManager, lrcInstance->getAppVersionManager())
    QML_REGISTERSINGLETONTYPE_WITH_INSTANCE(NameDirectory); // C++ singleton

    // QAbstractListModels
    QML_REGISTERTYPE(NS_MODELS, BannedListModel);
    QML_REGISTERTYPE(NS_MODELS, MediaCodecListModel);
    QML_REGISTERTYPE(NS_MODELS, AudioDeviceModel);
    QML_REGISTERTYPE(NS_MODELS, AudioManagerListModel);
    QML_REGISTERTYPE(NS_MODELS, PreferenceItemListModel);
    QML_REGISTERTYPE(NS_MODELS, PluginListPreferenceModel);
    QML_REGISTERTYPE(NS_MODELS, FilesToSendListModel);
    QML_REGISTERTYPE(NS_MODELS, CallInformationListModel);
    QML_REGISTERTYPE(NS_MODELS, SpellChecker);

    // Roles & type enums for models
    QML_REGISTERNAMESPACE(NS_MODELS, AccountList::staticMetaObject, "AccountList");
    QML_REGISTERNAMESPACE(NS_MODELS, ConversationList::staticMetaObject, "ConversationList");
    QML_REGISTERNAMESPACE(NS_MODELS, ContactList::staticMetaObject, "ContactList");
    QML_REGISTERNAMESPACE(NS_MODELS, FilesToSend::staticMetaObject, "FilesToSend");
    QML_REGISTERNAMESPACE(NS_MODELS, MessageList::staticMetaObject, "MessageList");
    QML_REGISTERNAMESPACE(NS_MODELS, PluginStatus::staticMetaObject, "PluginStatus");

    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, app, "MainApplication")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, screenInfo, "CurrentScreenInfo")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, lrcInstance, "LRCInstance")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, settingsManager, "AppSettingsManager")

    // Lrc namespaces, models, and singletons
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::staticMetaObject, "Lrc");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::account::staticMetaObject, "Account");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::call::staticMetaObject, "Call");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::datatransfer::staticMetaObject, "Datatransfer");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::interaction::staticMetaObject, "Interaction");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::member::staticMetaObject, "Member");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::video::staticMetaObject, "Video");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::profile::staticMetaObject, "Profile");
    QML_REGISTERNAMESPACE(NS_MODELS, lrc::api::conversation::staticMetaObject, "Conversation");

    // Same as QML_REGISTERUNCREATABLE but omit the namespace in Qml
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(AccountModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(BehaviorController, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(DataTransferModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(ContactModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(ConversationModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(CallModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(CallParticipants, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(DeviceModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(CodecModel, lrc::api);
    QML_REGISTERUNCREATABLE_IN_NAMESPACE(PeerDiscoveryModel, lrc::api);

    // Enums
    QML_REGISTERUNCREATABLE(NS_ENUMS, Settings)
    QML_REGISTERUNCREATABLE(NS_ENUMS, NetworkManager)
    QML_REGISTERUNCREATABLE(NS_ENUMS, WizardViewStepModel)
    QML_REGISTERUNCREATABLE(NS_ENUMS, DeviceItemListModel)
    QML_REGISTERUNCREATABLE(NS_ENUMS, ModeratorListModel)
    QML_REGISTERUNCREATABLE(NS_ENUMS, VideoInputDeviceModel)
    QML_REGISTERUNCREATABLE(NS_ENUMS, VideoFormatResolutionModel)
    QML_REGISTERUNCREATABLE(NS_ENUMS, VideoFormatFpsModel)

    engine->addImageProvider(QLatin1String("qrImage"), new QrImageProvider(lrcInstance));
    engine->addImageProvider(QLatin1String("avatarimage"), new AvatarImageProvider(lrcInstance));

    // Find modules (runtime) under the root source dir.
    engine->addImportPath("qrc:/");

    auto videoProvider = new VideoProvider(lrcInstance->avModel(), app);
    engine->rootContext()->setContextProperty("videoProvider", videoProvider);

    engine->rootContext()->setContextProperty("WITH_WEBENGINE", WITH_WEBENGINE);
    engine->rootContext()->setContextProperty("APPSTORE", APPSTORE);
}
// clang-format on
} // namespace Utils
