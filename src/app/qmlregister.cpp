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

#include "videodevices.h"
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

#include "appsettingsmanager.h"
#include "pluginversionmanager.h"
#include "pluginlistpreferencemodel.h"
#include "preferenceitemlistmodel.h"
#include "wizardviewstepmodel.h"

#include "api/peerdiscoverymodel.h"
#include "api/codecmodel.h"
#include "api/devicemodel.h"
#include "api/datatransfermodel.h"
#include "api/conversation.h"
#include "api/callparticipantsmodel.h"

#include <QMetaType>
#include <QQmlEngine>

namespace Utils {

/*!
 * This function will expose custom types to the QML engine.
 */
void
registerTypes(QQmlEngine* engine)
{
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
}
} // namespace Utils
