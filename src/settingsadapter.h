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

#pragma once

#include <QObject>
#include <QSettings>

#include "api/account.h"
#include "api/datatransfermodel.h"
#include "lrcinstance.h"
#include "typedefs.h"
#include "utils.h"

class SettingsAdapter : public QObject
{
    Q_OBJECT
public:
    explicit SettingsAdapter(QObject *parent = nullptr);

    //Singleton
    static SettingsAdapter &instance();
    /*
     * getters of directories
     */
    Q_INVOKABLE QString getDir_Document();
    Q_INVOKABLE QString getDir_Download();

    Q_INVOKABLE QVariant getAppValue(const Settings::Key key);
    Q_INVOKABLE void setAppValue(const Settings::Key key, const QVariant& value);

    Q_INVOKABLE void setRunOnStartUp(bool state);
    Q_INVOKABLE void setDownloadPath(QString dir);

    /*
     * getters of devices' Info and options
     */
    Q_INVOKABLE lrc::api::video::Capabilities get_DeviceCapabilities(const QString &device);
    Q_INVOKABLE lrc::api::video::ResRateList get_ResRateList(lrc::api::video::Channel channel,
                                                             QString device);
    Q_INVOKABLE int get_DeviceCapabilitiesSize(const QString &device);

    /*
     * getters of resolution and frame rates of current device
     */
    Q_INVOKABLE QVector<QString> getResolutions(const QString &device);
    Q_INVOKABLE QVector<int> getFrameRates(const QString &device);

    /*
     * getters and setters: lrc video::setting
     */
    Q_INVOKABLE QString get_Video_Settings_Channel(const QString &deviceId);
    Q_INVOKABLE QString get_Video_Settings_Name(const QString &deviceId);
    Q_INVOKABLE QString get_Video_Settings_Id(const QString &deviceId);
    Q_INVOKABLE qreal get_Video_Settings_Rate(const QString &deviceId);
    Q_INVOKABLE QString get_Video_Settings_Size(const QString &deviceId);

    Q_INVOKABLE void set_Video_Settings_Rate_And_Resolution(const QString &deviceId,
                                                            qreal rate,
                                                            const QString &resolution);

    Q_INVOKABLE lrc::api::ContactModel *getContactModel();
    Q_INVOKABLE lrc::api::NewDeviceModel *getDeviceModel();

    Q_INVOKABLE QString get_CurrentAccountInfo_RegisteredName();
    Q_INVOKABLE QString get_CurrentAccountInfo_Id();
    Q_INVOKABLE bool get_CurrentAccountInfo_Enabled();

    // profile info
    Q_INVOKABLE QString getCurrentAccount_Profile_Info_Uri();
    Q_INVOKABLE QString getCurrentAccount_Profile_Info_Alias();
    Q_INVOKABLE int getCurrentAccount_Profile_Info_Type();
    Q_INVOKABLE QString getAccountBestName();

    // getters and setters of avatar image
    Q_INVOKABLE QString getAvatarImage_Base64(int avatarSize);
    Q_INVOKABLE bool getIsDefaultAvatar();
    Q_INVOKABLE bool setCurrAccAvatar(QString avatarImgBase64);
    Q_INVOKABLE void clearCurrentAvatar();

    /*
     * getters and setters of Configuration properties
     */
    // getters
    Q_INVOKABLE lrc::api::account::ConfProperties_t getAccountConfig();
    Q_INVOKABLE QVariantMap getAccountConfigMap();
    Q_INVOKABLE QVariant getAccountConfig(const QString& key);


    // setters
    Q_INVOKABLE void setAccountConfigMap(const QVariantMap& configMap);
    Q_INVOKABLE void setAccountConfig(const QString& key, const QVariant& value);

    Q_INVOKABLE void setUseSDES(bool state);

    Q_INVOKABLE void tlsProtocolComboBoxIndexChanged(const int &index);

    Q_INVOKABLE void unbanContact(int index);

    Q_INVOKABLE void audioCodecsStateChange(unsigned int id, bool isToEnable);
    Q_INVOKABLE void videoCodecsStateChange(unsigned int id, bool isToEnable);

    Q_INVOKABLE void decreaseAudioCodecPriority(unsigned int id);
    Q_INVOKABLE void increaseAudioCodecPriority(unsigned int id);

    Q_INVOKABLE void decreaseVideoCodecPriority(unsigned int id);
    Q_INVOKABLE void increaseVideoCodecPriority(unsigned int id);

    // TODO: remove these
    const Q_INVOKABLE lrc::api::account::Info &getCurrentAccountInfo();
    const Q_INVOKABLE lrc::api::profile::Info &getCurrentAccount_Profile_Info();

};
Q_DECLARE_METATYPE(SettingsAdapter *)
