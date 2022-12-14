/******************************************************************************
 *   Copyright (C) 2014-2022 Savoir-faire Linux Inc.                          *
 *   Author : Philippe Groarke <philippe.groarke@savoirfairelinux.com>        *
 *   Author : Alexandre Lision <alexandre.lision@savoirfairelinux.com>        *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/
#pragma once

#include <QtCore/QObject>
#include <QtCore/QByteArray>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QTimer>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>

#include <future>

#include <configurationmanager_interface.h>
#include <datatransfer_interface.h>
#include <account_const.h>
#include <conversation_interface.h>

#include "typedefs.h"
#include "conversions_wrap.hpp"

/*
 * Proxy class for interface org.ring.Ring.ConfigurationManager
 */
class ConfigurationManagerInterface : public QObject
{
    Q_OBJECT

public:
    std::map<std::string, std::shared_ptr<libjami::CallbackWrapperBase>> confHandlers;
    std::map<std::string, std::shared_ptr<libjami::CallbackWrapperBase>> dataXferHandlers;
    std::map<std::string, std::shared_ptr<libjami::CallbackWrapperBase>> conversationsHandlers;

    ConfigurationManagerInterface()
    {
        setObjectName("ConfigurationManagerInterface");
        using libjami::exportable_callback;
        using libjami::ConfigurationSignal;
        using libjami::AudioSignal;
        using libjami::DataTransferSignal;
        using libjami::ConversationSignal;

        setObjectName("ConfigurationManagerInterface");
        confHandlers = {
            exportable_callback<ConfigurationSignal::VolumeChanged>(
                [this](const std::string& device, double value) {
                    Q_EMIT this->volumeChanged(QString(device.c_str()), value);
                }),
            exportable_callback<ConfigurationSignal::AccountsChanged>(
                [this]() { Q_EMIT this->accountsChanged(); }),
            exportable_callback<ConfigurationSignal::AccountDetailsChanged>(
                [this](const std::string& account_id,
                       const std::map<std::string, std::string>& details) {
                    Q_EMIT this->accountDetailsChanged(QString(account_id.c_str()),
                                                       convertMap(details));
                }),
            exportable_callback<ConfigurationSignal::StunStatusFailed>(
                [this](const std::string& reason) {
                    Q_EMIT this->stunStatusFailure(QString(reason.c_str()));
                }),
            exportable_callback<ConfigurationSignal::RegistrationStateChanged>(
                [this](const std::string& accountID,
                       const std::string& registration_state,
                       unsigned detail_code,
                       const std::string& detail_str) {
                    Q_EMIT this->registrationStateChanged(QString(accountID.c_str()),
                                                          QString(registration_state.c_str()),
                                                          detail_code,
                                                          QString(detail_str.c_str()));
                }),
            exportable_callback<ConfigurationSignal::VolatileDetailsChanged>(
                [this](const std::string& accountID,
                       const std::map<std::string, std::string>& details) {
                    Q_EMIT this->volatileAccountDetailsChanged(QString(accountID.c_str()),
                                                               convertMap(details));
                }),
            exportable_callback<ConfigurationSignal::CertificateExpired>(
                [this](const std::string& certId) {
                    Q_EMIT this->certificateExpired(QString(certId.c_str()));
                }),
            exportable_callback<ConfigurationSignal::CertificatePinned>(
                [this](const std::string& certId) {
                    Q_EMIT this->certificatePinned(QString(certId.c_str()));
                }),
            exportable_callback<ConfigurationSignal::CertificatePathPinned>(
                [this](const std::string& certPath, const std::vector<std::string>& list) {
                    Q_EMIT this->certificatePathPinned(QString(certPath.c_str()),
                                                       convertStringList(list));
                }),
            exportable_callback<ConfigurationSignal::CertificateStateChanged>(
                [this](const std::string& accountID,
                       const std::string& certId,
                       const std::string& state) {
                    QTimer::singleShot(0, [this, accountID, certId, state] {
                        Q_EMIT this->certificateStateChanged(QString(accountID.c_str()),
                                                             QString(certId.c_str()),
                                                             QString(state.c_str()));
                    });
                }),
            exportable_callback<libjami::ConfigurationSignal::AccountMessageStatusChanged>(
                [this](const std::string& account_id,
                       const std::string& conversation_id,
                       const std::string& peer,
                       const std::string message_id,
                       int state) {
                    Q_EMIT this->accountMessageStatusChanged(QString(account_id.c_str()),
                                                             QString(conversation_id.c_str()),
                                                             QString(peer.c_str()),
                                                             QString(message_id.c_str()),
                                                             state);
                }),
            exportable_callback<libjami::ConfigurationSignal::NeedsHost>(
                [this](const std::string& account_id, const std::string& conversation_id) {
                    Q_EMIT this->needsHost(QString(account_id.c_str()),
                                           QString(conversation_id.c_str()));
                }),
            exportable_callback<ConfigurationSignal::KnownDevicesChanged>(
                [this](const std::string& accountId,
                       const std::map<std::string, std::string>& devices) {
                    Q_EMIT this->knownDevicesChanged(QString(accountId.c_str()),
                                                     convertMap(devices));
                }),
            exportable_callback<ConfigurationSignal::DeviceRevocationEnded>(
                [this](const std::string& accountId, const std::string& device, int status) {
                    Q_EMIT this->deviceRevocationEnded(QString(accountId.c_str()),
                                                       QString(device.c_str()),
                                                       status);
                }),
            exportable_callback<ConfigurationSignal::AccountProfileReceived>(
                [this](const std::string& accountId,
                       const std::string& displayName,
                       const std::string& userPhoto) {
                    Q_EMIT this->accountProfileReceived(QString(accountId.c_str()),
                                                        QString(displayName.c_str()),
                                                        QString(userPhoto.c_str()));
                }),
            exportable_callback<ConfigurationSignal::ExportOnRingEnded>(
                [this](const std::string& accountId, int status, const std::string& pin) {
                    Q_EMIT this->exportOnRingEnded(QString(accountId.c_str()),
                                                   status,
                                                   QString(pin.c_str()));
                }),
            exportable_callback<ConfigurationSignal::NameRegistrationEnded>(
                [this](const std::string& accountId, int status, const std::string& name) {
                    Q_EMIT this->nameRegistrationEnded(QString(accountId.c_str()),
                                                       status,
                                                       QString(name.c_str()));
                }),
            exportable_callback<ConfigurationSignal::RegisteredNameFound>(
                [this](const std::string& accountId,
                       int status,
                       const std::string& address,
                       const std::string& name) {
                    Q_EMIT this->registeredNameFound(QString(accountId.c_str()),
                                                     status,
                                                     QString(address.c_str()),
                                                     QString(name.c_str()));
                }),
            exportable_callback<ConfigurationSignal::IncomingAccountMessage>(
                [this](const std::string& account_id,
                       const std::string& from,
                       const std::string& msgId,
                       const std::map<std::string, std::string>& payloads) {
                    Q_EMIT this->incomingAccountMessage(QString(account_id.c_str()),
                                                        QString(from.c_str()),
                                                        QString(msgId.c_str()),
                                                        convertMap(payloads));
                }),
            exportable_callback<ConfigurationSignal::MediaParametersChanged>(
                [this](const std::string& account_id) {
                    Q_EMIT this->mediaParametersChanged(QString(account_id.c_str()));
                }),
            exportable_callback<AudioSignal::DeviceEvent>(
                [this]() { Q_EMIT this->audioDeviceEvent(); }),
            exportable_callback<AudioSignal::AudioMeter>([this](const std::string& id, float level) {
                Q_EMIT this->audioMeter(QString(id.c_str()), level);
            }),
            exportable_callback<ConfigurationSignal::MigrationEnded>(
                [this](const std::string& account_id, const std::string& result) {
                    Q_EMIT this->migrationEnded(QString(account_id.c_str()),
                                                QString(result.c_str()));
                }),
            exportable_callback<ConfigurationSignal::ContactAdded>(
                [this](const std::string& account_id, const std::string& uri, const bool& confirmed) {
                    Q_EMIT this->contactAdded(QString(account_id.c_str()),
                                              QString(uri.c_str()),
                                              confirmed);
                }),
            exportable_callback<ConfigurationSignal::ProfileReceived>(
                [this](const std::string& accountID,
                       const std::string& peer,
                       const std::string& vCard) {
                    Q_EMIT this->profileReceived(QString(accountID.c_str()),
                                                 QString(peer.c_str()),
                                                 QString(vCard.c_str()));
                }),
            exportable_callback<ConfigurationSignal::ContactRemoved>(
                [this](const std::string& account_id, const std::string& uri, const bool& banned) {
                    Q_EMIT this->contactRemoved(QString(account_id.c_str()),
                                                QString(uri.c_str()),
                                                banned);
                }),
            exportable_callback<ConfigurationSignal::MessageSend>(
                [this](const std::string& message) {
                    Q_EMIT this->messageSend(QString(message.c_str()));
                }),
            exportable_callback<ConfigurationSignal::ComposingStatusChanged>(
                [this](const std::string& account_id,
                       const std::string& convId,
                       const std::string& from,
                       int status) {
                    Q_EMIT this->composingStatusChanged(QString(account_id.c_str()),
                                                        QString(convId.c_str()),
                                                        QString(from.c_str()),
                                                        status > 0 ? true : false);
                }),
            exportable_callback<ConfigurationSignal::UserSearchEnded>(
                [this](const std::string& account_id,
                       int status,
                       const std::string& query,
                       const std::vector<std::map<std::string, std::string>>& results) {
                    Q_EMIT this->userSearchEnded(QString(account_id.c_str()),
                                                 status,
                                                 QString(query.c_str()),
                                                 convertVecMap(results));
                }),
        };

        dataXferHandlers = {
            exportable_callback<DataTransferSignal::DataTransferEvent>(
                [this](const std::string& accountId,
                       const std::string& conversationId,
                       const std::string& interactionId,
                       const std::string& fileId,
                       const uint32_t& code) {
                    Q_EMIT this->dataTransferEvent(QString(accountId.c_str()),
                                                   QString(conversationId.c_str()),
                                                   QString(interactionId.c_str()),
                                                   QString(fileId.c_str()),
                                                   code);
                }),
        };
        conversationsHandlers
            = {exportable_callback<ConversationSignal::ConversationLoaded>(
                   [this](uint32_t id,
                          const std::string& accountId,
                          const std::string& conversationId,
                          const std::vector<std::map<std::string, std::string>>& messages) {
                       Q_EMIT conversationLoaded(id,
                                                 QString(accountId.c_str()),
                                                 QString(conversationId.c_str()),
                                                 convertVecMap(messages));
                   }),
               exportable_callback<ConversationSignal::MessagesFound>(
                   [this](uint32_t id,
                          const std::string& accountId,
                          const std::string& conversationId,
                          const std::vector<std::map<std::string, std::string>>& messages) {
                       Q_EMIT messagesFound(id,
                                            QString(accountId.c_str()),
                                            QString(conversationId.c_str()),
                                            convertVecMap(messages));
                   }),
               exportable_callback<ConversationSignal::MessageReceived>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::map<std::string, std::string>& message) {
                       Q_EMIT messageReceived(QString(accountId.c_str()),
                                              QString(conversationId.c_str()),
                                              convertMap(message));
                   }),
               exportable_callback<ConversationSignal::ConversationProfileUpdated>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::map<std::string, std::string>& profile) {
                       Q_EMIT conversationProfileUpdated(QString(accountId.c_str()),
                                                         QString(conversationId.c_str()),
                                                         convertMap(profile));
                   }),
               exportable_callback<ConversationSignal::ConversationRequestReceived>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::map<std::string, std::string>& metadata) {
                       Q_EMIT conversationRequestReceived(QString(accountId.c_str()),
                                                          QString(conversationId.c_str()),
                                                          convertMap(metadata));
                   }),
               exportable_callback<ConversationSignal::ConversationRequestDeclined>(
                   [this](const std::string& accountId, const std::string& conversationId) {
                       Q_EMIT conversationRequestDeclined(QString(accountId.c_str()),
                                                          QString(conversationId.c_str()));
                   }),
               exportable_callback<ConversationSignal::ConversationReady>(
                   [this](const std::string& accountId, const std::string& conversationId) {
                       Q_EMIT conversationReady(QString(accountId.c_str()),
                                                QString(conversationId.c_str()));
                   }),
               exportable_callback<ConversationSignal::ConversationRemoved>(
                   [this](const std::string& accountId, const std::string& conversationId) {
                       Q_EMIT conversationRemoved(QString(accountId.c_str()),
                                                  QString(conversationId.c_str()));
                   }),
               exportable_callback<ConversationSignal::ConversationPreferencesUpdated>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::map<std::string, std::string>& preferences) {
                       Q_EMIT conversationPreferencesUpdated(QString(accountId.c_str()),
                                                             QString(conversationId.c_str()),
                                                             convertMap(preferences));
                   }),
               exportable_callback<ConversationSignal::ConversationMemberEvent>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::string& memberId,
                          int event) {
                       Q_EMIT conversationMemberEvent(QString(accountId.c_str()),
                                                      QString(conversationId.c_str()),
                                                      QString(memberId.c_str()),
                                                      event);
                   }),
               exportable_callback<ConversationSignal::OnConversationError>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          int code,
                          const std::string& what) {
                       Q_EMIT onConversationError(QString(accountId.c_str()),
                                                  QString(conversationId.c_str()),
                                                  code,
                                                  QString(what.c_str()));
                   }),
               exportable_callback<ConfigurationSignal::ActiveCallsChanged>(
                   [this](const std::string& accountId,
                          const std::string& conversationId,
                          const std::vector<std::map<std::string, std::string>>& activeCalls) {
                       Q_EMIT activeCallsChanged(QString(accountId.c_str()),
                                                 QString(conversationId.c_str()),
                                                 convertVecMap(activeCalls));
                   })};
    }

    ~ConfigurationManagerInterface() {}

public Q_SLOTS: // METHODS
    QString addAccount(MapStringString details)
    {
        QString temp(libjami::addAccount(convertMap(details)).c_str());
        return temp;
    }

    void downloadFile(const QString& accountId,
                      const QString& convId,
                      const QString& interactionId,
                      const QString& fileId,
                      const QString& path)
    {
        libjami::downloadFile(accountId.toStdString(),
                              convId.toStdString(),
                              interactionId.toStdString(),
                              fileId.toStdString(),
                              path.toStdString());
    }

    bool exportOnRing(const QString& accountID, const QString& password)
    {
        return libjami::exportOnRing(accountID.toStdString(), password.toStdString());
    }

    bool exportToFile(const QString& accountID,
                      const QString& destinationPath,
                      const QString& password = {})
    {
        return libjami::exportToFile(accountID.toStdString(),
                                     destinationPath.toStdString(),
                                     password.toStdString());
    }

    MapStringString getKnownRingDevices(const QString& accountID)
    {
        MapStringString temp = convertMap(libjami::getKnownRingDevices(accountID.toStdString()));
        return temp;
    }

    bool lookupName(const QString& accountID, const QString& nameServiceURL, const QString& name)
    {
        return libjami::lookupName(accountID.toStdString(),
                                   nameServiceURL.toStdString(),
                                   name.toStdString());
    }

    bool lookupAddress(const QString& accountID,
                       const QString& nameServiceURL,
                       const QString& address)
    {
        return libjami::lookupAddress(accountID.toStdString(),
                                      nameServiceURL.toStdString(),
                                      address.toStdString());
    }

    bool registerName(const QString& accountID, const QString& password, const QString& name)
    {
        return libjami::registerName(accountID.toStdString(),
                                     password.toStdString(),
                                     name.toStdString());
    }

    MapStringString getAccountDetails(const QString& accountID)
    {
        MapStringString temp = convertMap(libjami::getAccountDetails(accountID.toStdString()));
        return temp;
    }

    QStringList getAccountList()
    {
        return convertStringList(libjami::getAccountList());
    }

    VectorMapStringString getActiveCalls(const QString& accountId, const QString& convId)
    {
        VectorMapStringString temp;
        for (const auto& x :
             libjami::getActiveCalls(accountId.toStdString(), convId.toStdString())) {
            temp.push_back(convertMap(x));
        }
        return temp;
    }

    MapStringString getAccountTemplate(const QString& accountType)
    {
        MapStringString temp = convertMap(libjami::getAccountTemplate(accountType.toStdString()));
        return temp;
    }

    // TODO: works?
    VectorUInt getActiveCodecList(const QString& accountId)
    {
        std::vector<unsigned int> v = libjami::getActiveCodecList(accountId.toStdString());
        return QVector<unsigned int>(v.begin(), v.end());
    }

    QString getAddrFromInterfaceName(const QString& interface)
    {
        QString temp(libjami::getAddrFromInterfaceName(interface.toStdString()).c_str());
        return temp;
    }

    QStringList getAllIpInterface()
    {
        QStringList temp = convertStringList(libjami::getAllIpInterface());
        return temp;
    }

    QStringList getAllIpInterfaceByName()
    {
        QStringList temp = convertStringList(libjami::getAllIpInterfaceByName());
        return temp;
    }

    MapStringString getCodecDetails(const QString& accountID, int payload)
    {
        MapStringString temp = convertMap(
            libjami::getCodecDetails(accountID.toStdString().c_str(), payload));
        return temp;
    }

    VectorUInt getCodecList()
    {
        std::vector<unsigned int> v = libjami::getCodecList();
        return QVector<unsigned int>(v.begin(), v.end());
    }

    VectorMapStringString getContacts(const QString& accountID)
    {
        VectorMapStringString temp;
        for (const auto& x : libjami::getContacts(accountID.toStdString())) {
            temp.push_back(convertMap(x));
        }
        return temp;
    }

    int getAudioInputDeviceIndex(const QString& devname)
    {
        return libjami::getAudioInputDeviceIndex(devname.toStdString());
    }

    QStringList getAudioInputDeviceList()
    {
        QStringList temp = convertStringList(libjami::getAudioInputDeviceList());
        return temp;
    }

    QString getAudioManager()
    {
        QString temp(libjami::getAudioManager().c_str());
        return temp;
    }

    int getAudioOutputDeviceIndex(const QString& devname)
    {
        return libjami::getAudioOutputDeviceIndex(devname.toStdString());
    }

    QStringList getAudioOutputDeviceList()
    {
        QStringList temp = convertStringList(libjami::getAudioOutputDeviceList());
        return temp;
    }

    QStringList getAudioPluginList()
    {
        QStringList temp = convertStringList(libjami::getAudioPluginList());
        return temp;
    }

    VectorMapStringString getCredentials(const QString& accountID)
    {
        VectorMapStringString temp;
        for (auto x : libjami::getCredentials(accountID.toStdString())) {
            temp.push_back(convertMap(x));
        }
        return temp;
    }

    QStringList getCurrentAudioDevicesIndex()
    {
        QStringList temp = convertStringList(libjami::getCurrentAudioDevicesIndex());
        return temp;
    }

    QString getCurrentAudioOutputPlugin()
    {
        QString temp(libjami::getCurrentAudioOutputPlugin().c_str());
        return temp;
    }

    int getHistoryLimit()
    {
        return libjami::getHistoryLimit();
    }

    bool getIsAlwaysRecording()
    {
        return libjami::getIsAlwaysRecording();
    }

    QString getNoiseSuppressState()
    {
        return libjami::getNoiseSuppressState().c_str();
    }

    QString getRecordPath()
    {
        QString temp(libjami::getRecordPath().c_str());
        return temp;
    }

    bool getRecordPreview()
    {
        return libjami::getRecordPreview();
    }

    int getRecordQuality()
    {
        return libjami::getRecordQuality();
    }

    QStringList getSupportedAudioManagers()
    {
        return convertStringList(libjami::getSupportedAudioManagers());
    }

    double getVolume(const QString& device)
    {
        return libjami::getVolume(device.toStdString());
    }

    bool isAgcEnabled()
    {
        return libjami::isAgcEnabled();
    }

    bool isCaptureMuted()
    {
        return libjami::isCaptureMuted();
    }

    bool isDtmfMuted()
    {
        return libjami::isDtmfMuted();
    }

    bool isPlaybackMuted()
    {
        return libjami::isPlaybackMuted();
    }

    void muteCapture(bool mute)
    {
        libjami::muteCapture(mute);
    }

    void muteDtmf(bool mute)
    {
        libjami::muteDtmf(mute);
    }

    void mutePlayback(bool mute)
    {
        libjami::mutePlayback(mute);
    }

    void registerAllAccounts()
    {
        libjami::registerAllAccounts();
    }

    void monitor(bool continuous)
    {
        libjami::monitor(continuous);
    }

    void removeAccount(const QString& accountID)
    {
        libjami::removeAccount(accountID.toStdString());
    }

    bool changeAccountPassword(const QString& id,
                               const QString& currentPassword,
                               const QString& newPassword)
    {
        return libjami::changeAccountPassword(id.toStdString(),
                                              currentPassword.toStdString(),
                                              newPassword.toStdString());
    }

    void sendRegister(const QString& accountID, bool enable)
    {
        libjami::sendRegister(accountID.toStdString(), enable);
    }

    void setAccountDetails(const QString& accountID, MapStringString details)
    {
        libjami::setAccountDetails(accountID.toStdString(), convertMap(details));
    }

    void setAccountsOrder(const QString& order)
    {
        libjami::setAccountsOrder(order.toStdString());
    }

    void setActiveCodecList(const QString& accountID, VectorUInt& list)
    {
        // const std::vector<unsigned int> converted = convertStringList(list);
        libjami::setActiveCodecList(accountID.toStdString(),
                                    std::vector<unsigned>(list.begin(), list.end()));
    }

    void setAgcState(bool enabled)
    {
        libjami::setAgcState(enabled);
    }

    void setAudioInputDevice(int index)
    {
        libjami::setAudioInputDevice(index);
    }

    bool setAudioManager(const QString& api)
    {
        return libjami::setAudioManager(api.toStdString());
    }

    void setAudioOutputDevice(int index)
    {
        libjami::setAudioOutputDevice(index);
    }

    void setAudioPlugin(const QString& audioPlugin)
    {
        libjami::setAudioPlugin(audioPlugin.toStdString());
    }

    void setAudioRingtoneDevice(int index)
    {
        libjami::setAudioRingtoneDevice(index);
    }

    void setCredentials(const QString& accountID, VectorMapStringString credentialInformation)
    {
        std::vector<std::map<std::string, std::string>> temp;
        for (auto x : credentialInformation) {
            temp.push_back(convertMap(x));
        }
        libjami::setCredentials(accountID.toStdString(), temp);
    }

    void setHistoryLimit(int days)
    {
        libjami::setHistoryLimit(days);
    }

    void setIsAlwaysRecording(bool enabled)
    {
        libjami::setIsAlwaysRecording(enabled);
    }

    void setNoiseSuppressState(QString state)
    {
        libjami::setNoiseSuppressState(state.toStdString());
    }

    bool isAudioMeterActive(const QString& id)
    {
        return libjami::isAudioMeterActive(id.toStdString());
    }

    void setAudioMeterState(const QString& id, bool state)
    {
        libjami::setAudioMeterState(id.toStdString(), state);
    }

    void setRecordPath(const QString& rec)
    {
        libjami::setRecordPath(rec.toStdString());
    }

    void setRecordPreview(const bool& rec)
    {
        libjami::setRecordPreview(rec);
    }

    void setRecordQuality(const int& quality)
    {
        libjami::setRecordQuality(quality);
    }

    void setVolume(const QString& device, double value)
    {
        libjami::setVolume(device.toStdString(), value);
    }

    MapStringString getVolatileAccountDetails(const QString& accountID)
    {
        MapStringString temp = convertMap(
            libjami::getVolatileAccountDetails(accountID.toStdString()));
        return temp;
    }

    VectorMapStringString getTrustRequests(const QString& accountId)
    {
        return convertVecMap(libjami::getTrustRequests(accountId.toStdString()));
    }

    void sendTrustRequest(const QString& accountId, const QString& from, const QByteArray& payload)
    {
        std::vector<unsigned char> raw(payload.begin(), payload.end());
        libjami::sendTrustRequest(accountId.toStdString(), from.toStdString(), raw);
    }

    void removeContact(const QString& accountId, const QString& uri, bool ban)
    {
        libjami::removeContact(accountId.toStdString(), uri.toStdString(), ban);
    }

    void revokeDevice(const QString& accountId, const QString& password, const QString& deviceId)
    {
        libjami::revokeDevice(accountId.toStdString(),
                              password.toStdString(),
                              deviceId.toStdString());
    }

    void addContact(const QString& accountId, const QString& uri)
    {
        libjami::addContact(accountId.toStdString(), uri.toStdString());
    }

    uint64_t sendTextMessage(const QString& accountId,
                             const QString& to,
                             const QMap<QString, QString>& payloads)
    {
        return libjami::sendAccountTextMessage(accountId.toStdString(),
                                               to.toStdString(),
                                               convertMap(payloads));
    }

    QVector<Message> getLastMessages(const QString& accountID, const uint64_t& base_timestamp)
    {
        QVector<Message> result;
        for (auto& message : libjami::getLastMessages(accountID.toStdString(), base_timestamp)) {
            result.append({message.from.c_str(), convertMap(message.payloads), message.received});
        }
        return result;
    }

    bool setCodecDetails(const QString& accountId,
                         unsigned int codecId,
                         const MapStringString& details)
    {
        return libjami::setCodecDetails(accountId.toStdString(), codecId, convertMap(details));
    }

    int getMessageStatus(uint64_t id)
    {
        return libjami::getMessageStatus(id);
    }

    MapStringString getNearbyPeers(const QString& accountID)
    {
        return convertMap(libjami::getNearbyPeers(accountID.toStdString()));
    }

    void connectivityChanged()
    {
        libjami::connectivityChanged();
    }

    MapStringString getContactDetails(const QString& accountID, const QString& uri)
    {
        return convertMap(libjami::getContactDetails(accountID.toStdString(), uri.toStdString()));
    }

    void sendFile(const QString& accountId,
                  const QString& conversationId,
                  const QString& filePath,
                  const QString& fileDisplayName,
                  const QString& parent)
    {
        libjami::sendFile(accountId.toStdString(),
                          conversationId.toStdString(),
                          filePath.toStdString(),
                          fileDisplayName.toStdString(),
                          parent.toStdString());
    }

    uint64_t fileTransferInfo(QString accountId,
                              QString conversationId,
                              QString fileId,
                              QString& path,
                              qlonglong& total,
                              qlonglong& progress)
    {
        std::string pathstr;
        auto result = uint32_t(libjami::fileTransferInfo(accountId.toStdString(),
                                                         conversationId.toStdString(),
                                                         fileId.toStdString(),
                                                         pathstr,
                                                         reinterpret_cast<int64_t&>(total),
                                                         reinterpret_cast<int64_t&>(progress)));
        path = pathstr.c_str();
        return result;
    }

    uint32_t cancelDataTransfer(QString accountId, QString conversationId, QString transfer_id)
    {
        return uint32_t(libjami::cancelDataTransfer(accountId.toStdString(),
                                                    conversationId.toStdString(),
                                                    transfer_id.toStdString()));
    }

    void setPushNotificationToken(const QString& token)
    {
        libjami::setPushNotificationToken(token.toStdString());
    }

    void pushNotificationReceived(const QString& from, const MapStringString& data)
    {
        libjami::pushNotificationReceived(from.toStdString(), convertMap(data));
    }

    void setIsComposing(const QString& accountId, const QString& contactId, bool isComposing)
    {
        libjami::setIsComposing(accountId.toStdString(), contactId.toStdString(), isComposing);
    }

    bool setMessageDisplayed(const QString& accountId,
                             const QString& contactId,
                             const QString& messageId,
                             int status)
    {
        return libjami::setMessageDisplayed(accountId.toStdString(),
                                            contactId.toStdString(),
                                            messageId.toStdString(),
                                            status);
    }

    bool searchUser(const QString& accountId, const QString& query)
    {
        return libjami::searchUser(accountId.toStdString(), query.toStdString());
    }
    // swarm
    QString startConversation(const QString& accountId)
    {
        auto convId = libjami::startConversation(accountId.toStdString());
        return QString(convId.c_str());
    }
    void acceptConversationRequest(const QString& accountId, const QString& conversationId)
    {
        libjami::acceptConversationRequest(accountId.toStdString(), conversationId.toStdString());
    }
    void declineConversationRequest(const QString& accountId, const QString& conversationId)
    {
        libjami::declineConversationRequest(accountId.toStdString(), conversationId.toStdString());
    }
    bool removeConversation(const QString& accountId, const QString& conversationId)
    {
        return libjami::removeConversation(accountId.toStdString(), conversationId.toStdString());
    }
    QStringList getConversations(const QString& accountId)
    {
        auto conversations = libjami::getConversations(accountId.toStdString());
        return convertStringList(conversations);
    }
    VectorMapStringString getConversationRequests(const QString& accountId)
    {
        auto requests = libjami::getConversationRequests(accountId.toStdString());
        return convertVecMap(requests);
    }
    void addConversationMember(const QString& accountId,
                               const QString& conversationId,
                               const QString& memberId)
    {
        libjami::addConversationMember(accountId.toStdString(),
                                       conversationId.toStdString(),
                                       memberId.toStdString());
    }
    void removeConversationMember(const QString& accountId,
                                  const QString& conversationId,
                                  const QString& memberId)
    {
        libjami::removeConversationMember(accountId.toStdString(),
                                          conversationId.toStdString(),
                                          memberId.toStdString());
    }
    VectorMapStringString getConversationMembers(const QString& accountId,
                                                 const QString& conversationId)
    {
        auto members = libjami::getConversationMembers(accountId.toStdString(),
                                                       conversationId.toStdString());
        return convertVecMap(members);
    }
    void sendMessage(const QString& accountId,
                     const QString& conversationId,
                     const QString& message,
                     const QString& parent,
                     int flags = 0)
    {
        libjami::sendMessage(accountId.toStdString(),
                             conversationId.toStdString(),
                             message.toStdString(),
                             parent.toStdString(),
                             flags);
    }

    uint32_t loadConversationMessages(const QString& accountId,
                                      const QString& conversationId,
                                      const QString& fromId,
                                      const int size)
    {
        return libjami::loadConversationMessages(accountId.toStdString(),
                                                 conversationId.toStdString(),
                                                 fromId.toStdString(),
                                                 size);
    }
    uint32_t loadConversationUntil(const QString& accountId,
                                   const QString& conversationId,
                                   const QString& fromId,
                                   const QString& toId)
    {
        return libjami::loadConversationUntil(accountId.toStdString(),
                                              conversationId.toStdString(),
                                              fromId.toStdString(),
                                              toId.toStdString());
    }

    void setDefaultModerator(const QString& accountID, const QString& peerURI, const bool& state)
    {
        libjami::setDefaultModerator(accountID.toStdString(), peerURI.toStdString(), state);
    }

    QStringList getDefaultModerators(const QString& accountID)
    {
        return convertStringList(libjami::getDefaultModerators(accountID.toStdString()));
    }

    void enableLocalModerators(const QString& accountID, const bool& isModEnabled)
    {
        libjami::enableLocalModerators(accountID.toStdString(), isModEnabled);
    }

    bool isLocalModeratorsEnabled(const QString& accountID)
    {
        return libjami::isLocalModeratorsEnabled(accountID.toStdString());
    }

    void setAllModerators(const QString& accountID, const bool& allModerators)
    {
        libjami::setAllModerators(accountID.toStdString(), allModerators);
    }

    bool isAllModerators(const QString& accountID)
    {
        return libjami::isAllModerators(accountID.toStdString());
    }

    MapStringString conversationInfos(const QString& accountId, const QString& conversationId)
    {
        return convertMap(
            libjami::conversationInfos(accountId.toStdString(), conversationId.toStdString()));
    }

    MapStringString getConversationPreferences(const QString& accountId,
                                               const QString& conversationId)
    {
        return convertMap(libjami::getConversationPreferences(accountId.toStdString(),
                                                              conversationId.toStdString()));
    }

    void updateConversationInfos(const QString& accountId,
                                 const QString& conversationId,
                                 const MapStringString& info)
    {
        libjami::updateConversationInfos(accountId.toStdString(),
                                         conversationId.toStdString(),
                                         convertMap(info));
    }

    void setConversationPreferences(const QString& accountId,
                                    const QString& conversationId,
                                    const MapStringString& prefs)
    {
        libjami::setConversationPreferences(accountId.toStdString(),
                                            conversationId.toStdString(),
                                            convertMap(prefs));
    }

    uint32_t countInteractions(const QString& accountId,
                               const QString& conversationId,
                               const QString& toId,
                               const QString& fromId,
                               const QString& authorUri)
    {
        return libjami::countInteractions(accountId.toStdString(),
                                          conversationId.toStdString(),
                                          toId.toStdString(),
                                          fromId.toStdString(),
                                          authorUri.toStdString());
    }
    uint32_t searchConversation(const QString& accountId,
                                const QString& conversationId,
                                const QString& author,
                                const QString& lastId,
                                const QString& regexSearch,
                                const QString& type,
                                const int64_t& after,
                                const int64_t& before,
                                const uint32_t& maxResult,
                                const int32_t& flag)
    {
        return libjami::searchConversation(accountId.toStdString(),
                                           conversationId.toStdString(),
                                           author.toStdString(),
                                           lastId.toStdString(),
                                           regexSearch.toStdString(),
                                           type.toStdString(),
                                           after,
                                           before,
                                           maxResult,
                                           flag);
    }
Q_SIGNALS: // SIGNALS
    void volumeChanged(const QString& device, double value);
    void accountsChanged();
    void accountDetailsChanged(const QString& accountId, const MapStringString& details);
    void historyChanged();
    void stunStatusFailure(const QString& reason);
    void registrationStateChanged(const QString& accountID,
                                  const QString& registration_state,
                                  unsigned detail_code,
                                  const QString& detail_str);
    void stunStatusSuccess(const QString& message);
    void volatileAccountDetailsChanged(const QString& accountID, MapStringString details);
    void certificatePinned(const QString& certId);
    void certificatePathPinned(const QString& path, const QStringList& certIds);
    void certificateExpired(const QString& certId);
    void certificateStateChanged(const QString& accountId,
                                 const QString& certId,
                                 const QString& status);
    void knownDevicesChanged(const QString& accountId, const MapStringString& devices);
    void exportOnRingEnded(const QString& accountId, int status, const QString& pin);
    void incomingAccountMessage(const QString& accountId,
                                const QString& from,
                                const QString msgId,
                                const MapStringString& payloads);
    void mediaParametersChanged(const QString& accountId);
    void audioDeviceEvent();
    void audioMeter(const QString& id, float level);
    void accountMessageStatusChanged(const QString& accountId,
                                     const QString& conversationId,
                                     const QString& peer,
                                     const QString& messageId,
                                     int status);
    void needsHost(const QString& accountId, const QString& conversationId);
    void nameRegistrationEnded(const QString& accountId, int status, const QString& name);
    void registeredNameFound(const QString& accountId,
                             int status,
                             const QString& address,
                             const QString& name);
    void migrationEnded(const QString& accountID, const QString& result);
    void contactAdded(const QString& accountID, const QString& uri, bool banned);
    void contactRemoved(const QString& accountID, const QString& uri, bool banned);
    void profileReceived(const QString& accountID, const QString& peer, const QString& vCard);
    void dataTransferEvent(const QString& accountId,
                           const QString& conversationId,
                           const QString& interactionId,
                           const QString& fileId,
                           uint code);
    void deviceRevocationEnded(const QString& accountId, const QString& deviceId, int status);
    void accountProfileReceived(const QString& accountId,
                                const QString& displayName,
                                const QString& userPhoto);
    void messageSend(const QString& message);
    void composingStatusChanged(const QString& accountId,
                                const QString& convId,
                                const QString& contactId,
                                bool isComposing);
    void userSearchEnded(const QString& accountId,
                         int status,
                         const QString& query,
                         VectorMapStringString results);
    // swarm
    void conversationLoaded(uint32_t requestId,
                            const QString& accountId,
                            const QString& conversationId,
                            const VectorMapStringString& messages);
    void messageReceived(const QString& accountId,
                         const QString& conversationId,
                         const MapStringString& message);
    void messagesFound(uint32_t requestId,
                       const QString& accountId,
                       const QString& conversationId,
                       const VectorMapStringString& messages);
    void conversationProfileUpdated(const QString& accountId,
                                    const QString& conversationId,
                                    const MapStringString& profile);
    void conversationRequestReceived(const QString& accountId,
                                     const QString& conversationId,
                                     const MapStringString& metadatas);
    void conversationRequestDeclined(const QString& accountId, const QString& conversationId);
    void conversationReady(const QString& accountId, const QString& conversationId);
    void conversationRemoved(const QString& accountId, const QString& conversationId);
    void conversationMemberEvent(const QString& accountId,
                                 const QString& conversationId,
                                 const QString& memberId,
                                 int event);
    void onConversationError(const QString& accountId,
                             const QString& conversationId,
                             int code,
                             const QString& what);
    void activeCallsChanged(const QString& accountId,
                            const QString& conversationId,
                            const VectorMapStringString& activeCalls);
    void conversationPreferencesUpdated(const QString& accountId,
                                        const QString& conversationId,
                                        const MapStringString& message);
};

namespace org {
namespace ring {
namespace Ring {
typedef ::ConfigurationManagerInterface ConfigurationManager;
}
} // namespace ring
} // namespace org
