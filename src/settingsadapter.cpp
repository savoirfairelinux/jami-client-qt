/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

#include "settingsadapter.h"

#include "api/newdevicemodel.h"

SettingsAdapter::SettingsAdapter(QObject *parent)
    : QObject(parent)
{}

///Singleton
SettingsAdapter &
SettingsAdapter::instance()
{
    static auto instance = new SettingsAdapter;
    return *instance;
}

QString
SettingsAdapter::getDir_Document()
{
    return QDir::toNativeSeparators(
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
}

QString
SettingsAdapter::getDir_Download()
{
    QString downloadPath = QDir::toNativeSeparators(LRCInstance::dataTransferModel().downloadDirectory);
    if (downloadPath.isEmpty()) {
        downloadPath = lrc::api::DataTransferModel::createDefaultDirectory();
        setDownloadPath(downloadPath);
        LRCInstance::dataTransferModel().downloadDirectory = downloadPath;
    }
#ifdef Q_OS_WIN
    int pos = downloadPath.lastIndexOf(QChar('\\'));
#else
    int pos = downloadPath.lastIndexOf(QChar('/'));
#endif
    if (pos == downloadPath.length() - 1)
        downloadPath.truncate(pos);
    return downloadPath;
}

QVariant
SettingsAdapter::getAppValue(const Settings::Key key)
{
    return AppSettingsManager::getValue(key);
}

void
SettingsAdapter::setAppValue(const Settings::Key key, const QVariant& value)
{
    AppSettingsManager::setValue(key, value);
}

void
SettingsAdapter::setRunOnStartUp(bool state)
{
    if (Utils::CheckStartupLink(L"Jami")) {
        if (!state) {
            Utils::DeleteStartupLink(L"Jami");
        }
    } else if (state) {
        Utils::CreateStartupLink(L"Jami");
    }
}

void
SettingsAdapter::setDownloadPath(QString dir)
{
    setAppValue(Settings::Key::DownloadPath, dir);
    LRCInstance::dataTransferModel().downloadDirectory = dir + "/";
}

lrc::api::video::ResRateList
SettingsAdapter::get_ResRateList(lrc::api::video::Channel channel, QString device)
{
    auto deviceCapabilities = get_DeviceCapabilities(device);

    return deviceCapabilities[channel];
}

int
SettingsAdapter::get_DeviceCapabilitiesSize(const QString &device)
{
    return get_DeviceCapabilities(device).size();
}

QVector<QString>
SettingsAdapter::getResolutions(const QString &device)
{
    QVector<QString> resolutions;

    auto currentSettings = LRCInstance::avModel().getDeviceSettings(device);

    auto currentChannel = currentSettings.channel.isEmpty() ? "default" : currentSettings.channel;
    auto channelCaps = get_ResRateList(currentChannel, device);
    for (auto [resolution, frameRateList] : channelCaps) {
        for (auto rate : frameRateList) {
            resolutions.append(resolution);
        }
    }

    return resolutions;
}

QVector<int>
SettingsAdapter::getFrameRates(const QString &device)
{
    QVector<int> rates;

    auto currentSettings = LRCInstance::avModel().getDeviceSettings(device);

    auto currentChannel = currentSettings.channel.isEmpty() ? "default" : currentSettings.channel;
    auto channelCaps = get_ResRateList(currentChannel, device);
    for (auto [resolution, frameRateList] : channelCaps) {
        for (auto rate : frameRateList) {
            rates.append((int) rate);
        }
    }

    return rates;
}

lrc::api::video::Capabilities
SettingsAdapter::get_DeviceCapabilities(const QString &device)
{
    return LRCInstance::avModel().getDeviceCapabilities(device);
}

QString
SettingsAdapter::get_Video_Settings_Channel(const QString &deviceId)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);

    return (QString) settings.channel;
}

QString
SettingsAdapter::get_Video_Settings_Name(const QString &deviceId)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);

    return (QString) settings.name;
}

QString
SettingsAdapter::get_Video_Settings_Id(const QString &deviceId)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);

    return (QString) settings.id;
}

qreal
SettingsAdapter::get_Video_Settings_Rate(const QString &deviceId)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);

    return (qreal) settings.rate;
}

QString
SettingsAdapter::get_Video_Settings_Size(const QString &deviceId)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);

    return (QString) settings.size;
}

void
SettingsAdapter::set_Video_Settings_Rate_And_Resolution(const QString &deviceId,
                                                        qreal rate,
                                                        const QString &resolution)
{
    auto settings = LRCInstance::avModel().getDeviceSettings(deviceId);
    settings.rate = rate;
    settings.size = resolution;
    LRCInstance::avModel().setDeviceSettings(settings);
}

const lrc::api::account::Info &
SettingsAdapter::getCurrentAccountInfo()
{
    return LRCInstance::getCurrentAccountInfo();
}

const Q_INVOKABLE lrc::api::profile::Info &
SettingsAdapter::getCurrentAccount_Profile_Info()
{
    return LRCInstance::getCurrentAccountInfo().profileInfo;
}

lrc::api::ContactModel *
SettingsAdapter::getContactModel()
{
    return getCurrentAccountInfo().contactModel.get();
}

lrc::api::NewDeviceModel *
SettingsAdapter::getDeviceModel()
{
    return getCurrentAccountInfo().deviceModel.get();
}

QString
SettingsAdapter::get_CurrentAccountInfo_RegisteredName()
{
    return LRCInstance::getCurrentAccountInfo().registeredName;
}

QString
SettingsAdapter::get_CurrentAccountInfo_Id()
{
    return LRCInstance::getCurrentAccountInfo().id;
}

bool
SettingsAdapter::get_CurrentAccountInfo_Enabled()
{
    return LRCInstance::getCurrentAccountInfo().enabled;
}

QString
SettingsAdapter::getCurrentAccount_Profile_Info_Uri()
{
    return getCurrentAccount_Profile_Info().uri;
}

QString
SettingsAdapter::getCurrentAccount_Profile_Info_Alias()
{
    return getCurrentAccount_Profile_Info().alias;
}

int
SettingsAdapter::getCurrentAccount_Profile_Info_Type()
{
    return (int) (getCurrentAccount_Profile_Info().type);
}

QString
SettingsAdapter::getAccountBestName()
{
    return Utils::bestNameForAccount(LRCInstance::getCurrentAccountInfo());
}

QString
SettingsAdapter::getAvatarImage_Base64(int avatarSize)
{
    auto &accountInfo = LRCInstance::getCurrentAccountInfo();
    auto avatar = Utils::accountPhoto(accountInfo, {avatarSize, avatarSize});

    return QString::fromLatin1(Utils::QImageToByteArray(avatar).toBase64().data());
}

bool
SettingsAdapter::getIsDefaultAvatar()
{
    auto &accountInfo = LRCInstance::getCurrentAccountInfo();

    return accountInfo.profileInfo.avatar.isEmpty();
}

bool
SettingsAdapter::setCurrAccAvatar(QString avatarImgBase64)
{
    QImage avatarImg;
    const bool ret = avatarImg.loadFromData(QByteArray::fromBase64(avatarImgBase64.toLatin1()));
    if (!ret) {
        qDebug() << "Current avatar loading from base64 fail";
        return false;
    } else {
        LRCInstance::setCurrAccAvatar(QPixmap::fromImage(avatarImg));
    }
    return true;
}

void
SettingsAdapter::clearCurrentAvatar()
{
    LRCInstance::setCurrAccAvatar(QPixmap());
}



lrc::api::account::ConfProperties_t
SettingsAdapter::getAccountConfig()
{
    lrc::api::account::ConfProperties_t res;
    try {
        res = LRCInstance::accountModel().getAccountConfig(LRCInstance::getCurrAccId());
    } catch (...) {}
    return res;
}

QVariantMap
SettingsAdapter::getAccountConfigMap()
{
    try {
        return LRCInstance::accountModel().getAccountConfigMap(LRCInstance::getCurrAccId());
    } catch (...) {}
    return QVariantMap();
}

QVariant
SettingsAdapter::getAccountConfig(const QString& key)
{
    return getAccountConfigMap()[key];
}

void
SettingsAdapter::setAccountConfigMap(const QVariantMap& configMap)
{
    LRCInstance::accountModel().setAccountConfig(
            LRCInstance::getCurrAccId(),
            configMap);
}

void
SettingsAdapter::setAccountConfig(const QString& key, const QVariant& value)
{
    auto configMap = getAccountConfigMap();
    qInfo() << "Changed: " << key << " to: " << value.toString();
    configMap[key] = value;
    setAccountConfigMap(configMap);
}

void
SettingsAdapter::tlsProtocolComboBoxIndexChanged(const int &index)
{
    auto confProps = LRCInstance::accountModel().getAccountConfig(LRCInstance::getCurrAccId());

    if (static_cast<int>(confProps.TLS.method) != index) {
        if (index == 0) {
            confProps.TLS.method = lrc::api::account::TlsMethod::DEFAULT;
        } else if (index == 1) {
            confProps.TLS.method = lrc::api::account::TlsMethod::TLSv1;
        } else if (index == 2) {
            confProps.TLS.method = lrc::api::account::TlsMethod::TLSv1_1;
        } else {
            confProps.TLS.method = lrc::api::account::TlsMethod::TLSv1_2;
        }
        LRCInstance::accountModel().setAccountConfig(LRCInstance::getCurrAccId(), confProps);
    }
}

void
SettingsAdapter::unbanContact(int index)
{
    auto bannedContactList = LRCInstance::getCurrentAccountInfo().contactModel->getBannedContacts();
    auto it = bannedContactList.begin();
    std::advance(it, index);

    auto contactInfo = LRCInstance::getCurrentAccountInfo().contactModel->getContact(*it);

    LRCInstance::getCurrentAccountInfo().contactModel->addContact(contactInfo);
}

void
SettingsAdapter::audioCodecsStateChange(unsigned int id, bool isToEnable)
{
    auto audioCodecList = LRCInstance::getCurrentAccountInfo().codecModel->getAudioCodecs();
    LRCInstance::getCurrentAccountInfo().codecModel->enable(id, isToEnable);
}

void
SettingsAdapter::videoCodecsStateChange(unsigned int id, bool isToEnable)
{
    auto videoCodecList = LRCInstance::getCurrentAccountInfo().codecModel->getVideoCodecs();
    LRCInstance::getCurrentAccountInfo().codecModel->enable(id, isToEnable);
}

void
SettingsAdapter::decreaseAudioCodecPriority(unsigned int id)
{
    LRCInstance::getCurrentAccountInfo().codecModel->decreasePriority(id, false);
}

void
SettingsAdapter::increaseAudioCodecPriority(unsigned int id)
{
    LRCInstance::getCurrentAccountInfo().codecModel->increasePriority(id, false);
}

void
SettingsAdapter::decreaseVideoCodecPriority(unsigned int id)
{
    LRCInstance::getCurrentAccountInfo().codecModel->decreasePriority(id, true);
}

void
SettingsAdapter::increaseVideoCodecPriority(unsigned int id)
{
    LRCInstance::getCurrentAccountInfo().codecModel->increasePriority(id, true);
}
