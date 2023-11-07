/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
#include "previewengine.h"
#include "imagedownloader.h"
#include "utilsadapter.h"
#include "conversationsadapter.h"
#include "currentcall.h"
#include "currentconversation.h"
#include "currentaccount.h"
#include "videodevices.h"
#include "currentaccounttomigrate.h"

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
#include "rendererinformationlistmodel.h"

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

#include "api/peerdiscoverymodel.h"
#include "api/codecmodel.h"
#include "api/devicemodel.h"
#include "api/datatransfermodel.h"
#include "api/pluginmodel.h"
#include "api/conversation.h"
#include "api/callparticipantsmodel.h"

#include <QMetaType>
#include <QQmlEngine>

// clang-format off
// TODO: remove this
#define QML_REGISTERSINGLETONTYPE_WITH_INSTANCE(T) \
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
              ScreenInfo* screenInfo,
              QObject* app)
{
    // setup the adapters (their lifetimes are that of MainApplication)
    auto callAdapter = new CallAdapter(settingsManager, systemTray, lrcInstance, engine);
    auto previewEngine = new PreviewEngine(connectivityMonitor, engine);
    auto imageDownloader = new ImageDownloader(connectivityMonitor, engine);
    auto messagesAdapter = new MessagesAdapter(settingsManager, previewEngine, lrcInstance, engine);
    auto positionManager = new PositionManager(settingsManager, systemTray, lrcInstance, engine);
    auto conversationsAdapter = new ConversationsAdapter(systemTray, lrcInstance, engine);
    auto avAdapter = new AvAdapter(lrcInstance, engine);
    auto contactAdapter = new ContactAdapter(lrcInstance, engine);
    auto accountAdapter = new AccountAdapter(settingsManager, systemTray, lrcInstance, engine);
    auto utilsAdapter = new UtilsAdapter(settingsManager, systemTray, lrcInstance, engine);
    auto pluginAdapter = new PluginAdapter(lrcInstance, settingsManager, engine);
    auto currentCall = new CurrentCall(lrcInstance, engine);
    auto currentConversation = new CurrentConversation(lrcInstance, engine);
    auto currentAccount = new CurrentAccount(lrcInstance, settingsManager, engine);
    auto tipsModel = new TipsModel(settingsManager, engine);
    auto videoDevices = new VideoDevices(lrcInstance, engine);
    auto currentAccountToMigrate = new CurrentAccountToMigrate(lrcInstance, engine);
    auto avatarRegistry = new AvatarRegistry(lrcInstance, engine);
    auto wizardViewStepModel = new WizardViewStepModel(lrcInstance, accountAdapter, settingsManager, engine);

    // qml adapter registration
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, callAdapter, "CallAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, tipsModel, "TipsModel");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, messagesAdapter, "MessagesAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, positionManager, "PositionManager");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, conversationsAdapter, "ConversationsAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, avAdapter, "AvAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, contactAdapter, "ContactAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, accountAdapter, "AccountAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, utilsAdapter, "UtilsAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, pluginAdapter, "PluginAdapter");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, currentCall, "CurrentCall");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, currentConversation, "CurrentConversation");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, currentConversation->uris(), "CurrentConversationMembers");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, currentAccount, "CurrentAccount");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, videoDevices, "VideoDevices");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_ADAPTERS, currentAccountToMigrate, "CurrentAccountToMigrate")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_HELPERS, avatarRegistry, "AvatarRegistry");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, wizardViewStepModel, "WizardViewStepModel")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_HELPERS, imageDownloader, "ImageDownloader")

    // TODO: remove these
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, AVModel, &lrcInstance->avModel())
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_MODELS, PluginModel, &lrcInstance->pluginModel())
    QML_REGISTERSINGLETONTYPE_CUSTOM(NS_HELPERS, AppVersionManager, lrcInstance->getAppVersionManager())

    // Hack for QtCreator autocomplete (part 2)
    // https://bugreports.qt.io/browse/QTCREATORBUG-20569
    // Use a dummy object to register the import namespace.
    // This occurs when we register from within MainApplication
    QML_REGISTERNAMESPACE(NS_MODELS, dummy::staticMetaObject, "");
    QML_REGISTERNAMESPACE(NS_ADAPTERS, dummy::staticMetaObject, "");
    QML_REGISTERNAMESPACE(NS_CONSTANTS, dummy::staticMetaObject, "");
    QML_REGISTERNAMESPACE(NS_HELPERS, dummy::staticMetaObject, "");
    QML_REGISTERNAMESPACE(NS_ENUMS, dummy::staticMetaObject, "");

    // QAbstractListModels
    QML_REGISTERTYPE(NS_MODELS, BannedListModel);
    QML_REGISTERTYPE(NS_MODELS, MediaCodecListModel);
    QML_REGISTERTYPE(NS_MODELS, AudioDeviceModel);
    QML_REGISTERTYPE(NS_MODELS, AudioManagerListModel);
    QML_REGISTERTYPE(NS_MODELS, PreferenceItemListModel);
    QML_REGISTERTYPE(NS_MODELS, PluginListPreferenceModel);
    QML_REGISTERTYPE(NS_MODELS, FilesToSendListModel);
    QML_REGISTERTYPE(NS_MODELS, SmartListModel);
    QML_REGISTERTYPE(NS_MODELS, MessageListModel);
    QML_REGISTERTYPE(NS_MODELS, CallInformationListModel);
    QML_REGISTERTYPE(NS_MODELS, RendererInformationListModel);

    // Roles & type enums for models
    QML_REGISTERNAMESPACE(NS_MODELS, AccountList::staticMetaObject, "AccountList");
    QML_REGISTERNAMESPACE(NS_MODELS, ConversationList::staticMetaObject, "ConversationList");
    QML_REGISTERNAMESPACE(NS_MODELS, ContactList::staticMetaObject, "ContactList");
    QML_REGISTERNAMESPACE(NS_MODELS, FilesToSend::staticMetaObject, "FilesToSend");
    QML_REGISTERNAMESPACE(NS_MODELS, MessageList::staticMetaObject, "MessageList");
    QML_REGISTERNAMESPACE(NS_MODELS, PluginStatus::staticMetaObject, "PluginStatus");

    // Qml singleton components
    QML_REGISTERSINGLETONTYPE_URL(NS_CONSTANTS, "qrc:/constant/JamiTheme.qml", JamiTheme);
    QML_REGISTERSINGLETONTYPE_URL(NS_MODELS, "qrc:/constant/JamiQmlUtils.qml", JamiQmlUtils);
    QML_REGISTERSINGLETONTYPE_URL(NS_CONSTANTS, "qrc:/constant/JamiStrings.qml", JamiStrings);
    QML_REGISTERSINGLETONTYPE_URL(NS_CONSTANTS, "qrc:/constant/JamiResources.qml", JamiResources);
    QML_REGISTERSINGLETONTYPE_URL(NS_CONSTANTS, "qrc:/constant/MsgSeq.qml", MsgSeq);

    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, app, "MainApplication")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, screenInfo, "CurrentScreenInfo")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, lrcInstance, "LRCInstance")
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_CONSTANTS, settingsManager, "AppSettingsManager")

    // C++ singletons
    // TODO: remove this
    QML_REGISTERSINGLETONTYPE_WITH_INSTANCE(NameDirectory);

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
    engine->addImageProvider(QLatin1String("avatarimage"),
                              new AvatarImageProvider(lrcInstance));

    engine->setObjectOwnership(&lrcInstance->avModel(), QQmlEngine::CppOwnership);
    engine->setObjectOwnership(&lrcInstance->pluginModel(), QQmlEngine::CppOwnership);
    engine->setObjectOwnership(lrcInstance->getAppVersionManager(), QQmlEngine::CppOwnership);
    engine->setObjectOwnership(&NameDirectory::instance(), QQmlEngine::CppOwnership);
}
// clang-format on
} // namespace Utils
