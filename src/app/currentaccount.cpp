/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

#include "currentaccount.h"

#include "utils.h"

CurrentAccount::CurrentAccount(LRCInstance* lrcInstance,
                               AppSettingsManager* settingsManager,
                               QObject* parent)
    : QObject(parent)
    , settingsManager_(settingsManager)
    , lrcInstance_(lrcInstance)
{
    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountStatusChanged,
            this,
            &CurrentAccount::onAccountUpdated);

    connect(&lrcInstance_->accountModel(),
            &AccountModel::profileUpdated,
            this,
            &CurrentAccount::onAccountUpdated);

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &CurrentAccount::setupForAccount,
            Qt::DirectConnection);

    setupForAccount();
}

void
CurrentAccount::enableAccount(bool enabled)
{
    lrcInstance_->accountModel().setAccountEnabled(lrcInstance_->get_currentAccountId(), enabled);
}

void
CurrentAccount::set_isAllModeratorsEnabled(bool enabled, bool initialize)
{
    if (enabled != isAllModeratorsEnabled_) {
        isAllModeratorsEnabled_ = enabled;
        if (!initialize)
            lrcInstance_->accountModel().setAllModerators(lrcInstance_->get_currentAccountId(),
                                                          enabled);
        Q_EMIT isAllModeratorsEnabledChanged();
    }
}

bool
CurrentAccount::get_isAllModeratorsEnabled()
{
    return isAllModeratorsEnabled_;
}

void
CurrentAccount::set_isLocalModeratorsEnabled(bool enabled, bool initialize)
{
    if (enabled != isLocalModeratorsEnabled_) {
        isLocalModeratorsEnabled_ = enabled;
        if (!initialize)
            lrcInstance_->accountModel().enableLocalModerators(lrcInstance_->get_currentAccountId(),
                                                               enabled);
        Q_EMIT isLocalModeratorsEnabledChanged();
    }
}

bool
CurrentAccount::get_isLocalModeratorsEnabled()
{
    return isLocalModeratorsEnabled_;
}

void
CurrentAccount::setupForAccount()
{
    if (lrcInstance_->get_currentAccountId().isEmpty())
        return;

    connect(lrcInstance_->getCurrentContactModel(),
            &ContactModel::bannedStatusChanged,
            this,
            &CurrentAccount::onBannedStatusChanged,
            Qt::UniqueConnection);
    updateData();
}

void
CurrentAccount::onAccountUpdated(const QString& id)
{
    // filter for our currently set id
    if (id_ != id)
        return;
    updateData();
}

void
CurrentAccount::onBannedStatusChanged(const QString& contactUri, bool banned)
{
    Q_UNUSED(contactUri)
    Q_UNUSED(banned)
    set_hasBannedContacts(
        lrcInstance_->getCurrentAccountInfo().contactModel->getBannedContacts().size());
}

void
CurrentAccount::updateData()
{
    set_id(lrcInstance_->get_currentAccountId());
    try {
        const auto& accConfig = lrcInstance_->getCurrAccConfig();
        const auto& accInfo = lrcInstance_->getCurrentAccountInfo();

        set_uri(accInfo.profileInfo.uri);
        set_registeredName(accInfo.registeredName);
        set_alias(accInfo.profileInfo.alias);
        set_bestId(lrcInstance_->accountModel().bestIdForAccount(id_));
        set_bestName(lrcInstance_->accountModel().bestNameForAccount(id_));
        set_hasAvatarSet(!accInfo.profileInfo.avatar.isEmpty());
        set_hasBannedContacts(
            lrcInstance_->getCurrentAccountInfo().contactModel->getBannedContacts().size());
        set_status(accInfo.status);
        set_type(accInfo.profileInfo.type);

        set_enabled(accInfo.enabled);
        set_managerUri(accConfig.managerUri);
        set_keepAliveEnabled(accConfig.keepAliveEnabled, true);
        set_deviceId(accConfig.deviceId);
        set_peerDiscovery(accConfig.peerDiscovery, true);
        set_sendReadReceipt(accConfig.sendReadReceipt, true);
        set_isRendezVous(accConfig.isRendezVous, true);
        set_autoAnswer(accConfig.autoAnswer, true);
        set_proxyEnabled(accConfig.proxyEnabled, true);
        set_upnpEnabled(accConfig.upnpEnabled, true);
        set_publishedSameAsLocal(accConfig.publishedSameAsLocal, true);
        set_allowIPAutoRewrite(accConfig.allowIPAutoRewrite, true);
        set_proxyServer(accConfig.proxyServer, true);
        set_routeset(accConfig.routeset, true);
        set_username(accConfig.username, true);
        set_hostname(accConfig.hostname, true);
        set_password(accConfig.password, true);
        set_mailbox(accConfig.mailbox, true);
        set_publishedAddress(accConfig.publishedAddress, true);
        set_localPort(accConfig.localPort, true);
        set_publishedPort(accConfig.publishedPort, true);
        set_registrationExpire(accConfig.registrationExpire, true);

        set_hasArchivePassword(accConfig.archiveHasPassword);

        // DHT
        set_PublicInCallsDHT(accConfig.DHT.PublicInCalls, true);

        // RingNS
        set_uriRingNS(accConfig.RingNS.uri, true);

        // TLS
        set_enableTLS(accConfig.TLS.enable, true);
        set_verifyServerTLS(accConfig.TLS.verifyServer, true);
        set_verifyClientTLS(accConfig.TLS.verifyClient, true);
        set_requireClientCertificateTLS(accConfig.TLS.requireClientCertificate, true);
        set_disableSecureDlgCheckTLS(accConfig.TLS.disableSecureDlgCheck, true);
        set_certificateListFileTLS(accConfig.TLS.certificateListFile, true);
        set_certificateFileTLS(accConfig.TLS.certificateFile, true);
        set_privateKeyFileTLS(accConfig.TLS.privateKeyFile, true);
        set_passwordTLS(accConfig.TLS.password, true);

        // SRTP
        set_enableSRTP(accConfig.SRTP.enable, true);
        set_keyExchangeSRTP(accConfig.SRTP.keyExchange, true);

        // TURN
        set_enableTURN(accConfig.TURN.enable, true);
        set_serverTURN(accConfig.TURN.server, true);
        set_usernameTURN(accConfig.TURN.username, true);
        set_passwordTURN(accConfig.TURN.password, true);
        set_realmTURN(accConfig.TURN.realm, true);

        // STUN
        set_enableSTUN(accConfig.STUN.enable, true);
        set_serverSTUN(accConfig.STUN.server, true);

        // Video & Audio
        set_videoEnabledVideo(accConfig.Video.videoEnabled, true);
        set_videoPortMinVideo(accConfig.Video.videoPortMin, true);
        set_videoPortMaxVideo(accConfig.Video.videoPortMax, true);
        set_audioPortMinAudio(accConfig.Audio.audioPortMin, true);
        set_audioPortMaxAudio(accConfig.Audio.audioPortMax, true);

        // Ringtone
        set_ringtoneEnabledRingtone(accConfig.Ringtone.ringtoneEnabled, true);
        set_ringtonePathRingtone(accConfig.Ringtone.ringtonePath, true);
        if (get_ringtonePathRingtone() == "default.opus" || get_ringtonePathRingtone().isEmpty()) {
            set_ringtonePathRingtone(Utils::GetRingtonePath(), true);
        }

        // Moderators
        set_isAllModeratorsEnabled(lrcInstance_->accountModel().isAllModerators(
                                       lrcInstance_->get_currentAccountId()),
                                   true);
        set_isLocalModeratorsEnabled(lrcInstance_->accountModel().isLocalModeratorsEnabled(
                                         lrcInstance_->get_currentAccountId()),
                                     true);

        // NewAccount model
        set_autoTransferFromTrusted(settingsManager_->getValue(Settings::Key::AutoAcceptFiles)
                                        .toBool(),
                                    true);
        set_autoTransferSizeThreshold(settingsManager_->getValue(Settings::Key::AcceptTransferBelow)
                                          .toInt(),
                                      true);

        // UI Customization settings
        set_uiCustomization(accConfig.uiCustomization, true);
    } catch (...) {
        qWarning() << "Can't update current account info data for" << id_;
    }
}
