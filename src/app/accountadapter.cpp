/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Yang Wang <yang.yang@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "accountadapter.h"

#include "appsettingsmanager.h"
#include "qtutils.h"
#include "systemtray.h"
#include "lrcinstance.h"
#include "accountlistmodel.h"

#include <QtConcurrent/QtConcurrent>

AccountAdapter::AccountAdapter(AppSettingsManager* settingsManager,
                               SystemTray* systemTray,
                               LRCInstance* instance,
                               QObject* parent)
    : QmlAdapterBase(instance, parent)
    , settingsManager_(settingsManager)
    , systemTray_(systemTray)
{
    connect(&lrcInstance_->accountModel(),
            &AccountModel::accountStatusChanged,
            this,
            &AccountAdapter::accountStatusChanged);

    connect(&lrcInstance_->accountModel(),
            &AccountModel::profileUpdated,
            this,
            &AccountAdapter::accountStatusChanged);

    connect(&lrcInstance_->accountModel(),
            &AccountModel::deviceAuthStateChanged,
            this,
            &AccountAdapter::deviceAuthStateChanged);

    connect(systemTray_,
            &SystemTray::countChanged,
            qApp->property("AccountListModel").value<AccountListModel*>(),
            &AccountListModel::updateNotifications);

    // Switch account to the specified index when an account is added.
    connect(this, &AccountAdapter::accountAdded, this, [this](const QString&, int index) {
        changeAccount(index);
    });
}

AccountModel*
AccountAdapter::getModel()
{
    return &(lrcInstance_->accountModel());
}

AccountAdapter*
AccountAdapter::create(QQmlEngine*, QJSEngine*)
{
    return new AccountAdapter(qApp->property("AppSettingsManager").value<AppSettingsManager*>(),
                              qApp->property("SystemTray").value<SystemTray*>(),
                              qApp->property("LRCInstance").value<LRCInstance*>());
}

void
AccountAdapter::changeAccount(int row)
{
    auto accountList = lrcInstance_->accountModel().getAccountList();
    if (accountList.size() > row) {
        lrcInstance_->set_currentAccountId(accountList.at(row));
    }
}

void
AccountAdapter::connectFailure()
{
    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountRemoved,
        [this](const QString& accountId) {
            Q_UNUSED(accountId);
            Q_EMIT accountCreationFailed();
            Q_EMIT reportFailure();
        },
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded);

    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::invalidAccountDetected,
        [this](const QString& accountId) {
            Q_UNUSED(accountId);
            Q_EMIT accountCreationFailed();
            Q_EMIT reportFailure();
        },
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded);
}

void
AccountAdapter::createJamiAccount(const QVariantMap& settings)
{
    auto registeredName = settings["registeredName"].toString();
    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded,
        [this, registeredName, settings](const QString& accountId) {
            lrcInstance_->accountModel().setAvatar(accountId, settings["avatar"].toString());
            Utils::oneShotConnect(&lrcInstance_->accountModel(),
                                  &lrc::api::AccountModel::accountDetailsChanged,
                                  [this](const QString& accountId) {
                                      Q_UNUSED(accountId);
                                      // For testing purpose
                                      Q_EMIT accountConfigFinalized();
                                  });

            auto confProps = lrcInstance_->accountModel().getAccountConfig(accountId);
#ifdef Q_OS_WIN
            confProps.Ringtone.ringtonePath = Utils::GetRingtonePath();
#endif
            confProps.isRendezVous = settings["isRendezVous"].toBool();
            lrcInstance_->accountModel().setAccountConfig(accountId, confProps);

            if (!registeredName.isEmpty()) {
                QObject::disconnect(registeredNameSavedConnection_);
                registeredNameSavedConnection_
                    = connect(&lrcInstance_->accountModel(),
                              &lrc::api::AccountModel::profileUpdated,
                              this,
                              [this, addedAccountId = accountId](const QString& accountId) {
                                  if (addedAccountId == accountId) {
                                      Q_EMIT lrcInstance_->accountListChanged();
                                      Q_EMIT accountAdded(accountId,
                                                          lrcInstance_->accountModel()
                                                              .getAccountList()
                                                              .indexOf(accountId));
                                      QObject::disconnect(registeredNameSavedConnection_);
                                  }
                              });

                lrcInstance_->accountModel().registerName(accountId,
                                                          settings["password"].toString(),
                                                          registeredName);
            } else {
                Q_EMIT lrcInstance_->accountListChanged();
                Q_EMIT accountAdded(accountId,
                                    lrcInstance_->accountModel().getAccountList().indexOf(
                                        accountId));
            }
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    auto futureResult = QtConcurrent::run([this, settings] {
        lrcInstance_->accountModel().createNewAccount(lrc::api::profile::Type::JAMI,
                                                      settings["alias"].toString(),
                                                      settings["archivePath"].toString(),
                                                      settings["password"].toString(),
                                                      settings["archivePin"].toString(),
                                                      "");
    });
}

// void
// AccountAdapter::deviceAuthStateChanged(const QString& accountId, int state, const QString& detail) {
//     Q_EMIT deviceAuthStateChanged(accountId, state, detail);
// }

void
AccountAdapter::startLinkDevice()
{
    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded,
        [this](const QString& accountId) {
            Utils::oneShotConnect(&lrcInstance_->accountModel(),
                                  &lrc::api::AccountModel::accountDetailsChanged,
                                  [this](const QString& accountId) {
                                      Q_UNUSED(accountId);
                                      // For testing purpose
                                      Q_EMIT accountConfigFinalized();
                                  });

            auto confProps = lrcInstance_->accountModel().getAccountConfig(accountId);
            qWarning() << "[LinkDevice] setting archivePath to jami-auth";
            confProps.archivePath = "jami-auth";
            // confProps.archive_path = "jami-auth";
            // confProps.archiveUrl = "jami-auth";
            // confProps.archiveURL = "jami-auth";
            // confProps.archive_url = "jami-auth";
            // confProps.ARCHIVE_URL = "jami-auth";
            lrcInstance_->accountModel().setAccountConfig(accountId, confProps);

            //     Q_EMIT lrcInstance_->accountListChanged();
            Q_EMIT accountAdded(accountId,
                                lrcInstance_->accountModel().getAccountList().indexOf(accountId));
        },
        this,
        &AccountAdapter::accountCreationFailed);

    // connectFailure();

    auto futureResult = QtConcurrent::run(
        [this] { lrcInstance_->accountModel().startLinkDevice(); });
}

void
AccountAdapter::createSIPAccount(const QVariantMap& settings)
{
    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded,
        [this, settings](const QString& accountId) {
            lrcInstance_->accountModel().setAvatar(accountId, settings["avatar"].toString());
            Utils::oneShotConnect(&lrcInstance_->accountModel(),
                                  &lrc::api::AccountModel::accountDetailsChanged,
                                  [this](const QString& accountId) {
                                      Q_UNUSED(accountId);
                                      // For testing purpose
                                      Q_EMIT accountConfigFinalized();
                                  });

            auto confProps = lrcInstance_->accountModel().getAccountConfig(accountId);
            // set SIP details
            confProps.hostname = settings["hostname"].toString();
            confProps.username = settings["username"].toString();
            confProps.password = settings["password"].toString();
            confProps.TLS.enable = settings["tls"].toBool();

#ifdef Q_OS_WIN
            confProps.Ringtone.ringtonePath = Utils::GetRingtonePath();
#endif
            lrcInstance_->accountModel().setAccountConfig(accountId, confProps);

            Q_EMIT lrcInstance_->accountListChanged();
            Q_EMIT accountAdded(accountId,
                                lrcInstance_->accountModel().getAccountList().indexOf(accountId));
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    auto futureResult = QtConcurrent::run([this, settings] {
        lrcInstance_->accountModel().createNewAccount(lrc::api::profile::Type::SIP,
                                                      settings["alias"].toString(),
                                                      settings["archivePath"].toString(),
                                                      "",
                                                      "",
                                                      settings["username"].toString(),
                                                      {});
    });
}

void
AccountAdapter::createJAMSAccount(const QVariantMap& settings)
{
    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded,
        [this](const QString& accountId) {
            if (!lrcInstance_->accountModel().getAccountCount())
                return;

            Utils::oneShotConnect(&lrcInstance_->accountModel(),
                                  &lrc::api::AccountModel::accountDetailsChanged,
                                  [this](const QString& accountId) {
                                      Q_UNUSED(accountId);
                                      // For testing purpose
                                      Q_EMIT accountConfigFinalized();
                                  });

            auto confProps = lrcInstance_->accountModel().getAccountConfig(accountId);
#ifdef Q_OS_WIN
            confProps.Ringtone.ringtonePath = Utils::GetRingtonePath();
#endif
            lrcInstance_->accountModel().setAccountConfig(accountId, confProps);

            Q_EMIT accountAdded(accountId,
                                lrcInstance_->accountModel().getAccountList().indexOf(accountId));
            Q_EMIT lrcInstance_->accountListChanged();
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    auto futureResult = QtConcurrent::run([this, settings] {
        lrcInstance_->accountModel().connectToAccountManager(settings["username"].toString(),
                                                             settings["password"].toString(),
                                                             settings["manager"].toString());
    });
}

void
AccountAdapter::deleteCurrentAccount()
{
    Utils::oneShotConnect(&lrcInstance_->accountModel(),
                          &lrc::api::AccountModel::accountRemoved,
                          [this](const QString& accountId) {
                              Q_EMIT accountRemoved(accountId);
                              Q_EMIT lrcInstance_->accountListChanged();
                          });

    lrcInstance_->accountModel().removeAccount(lrcInstance_->get_currentAccountId());
}

bool
AccountAdapter::savePassword(const QString& accountId,
                             const QString& oldPassword,
                             const QString& newPassword)
{
    return lrcInstance_->accountModel().changeAccountPassword(accountId, oldPassword, newPassword);
}

bool
AccountAdapter::hasVideoCall()
{
    return lrcInstance_->hasActiveCall(true);
}

void
AccountAdapter::setCurrAccDisplayName(const QString& text)
{
    lrcInstance_->setCurrAccDisplayName(text);
}

void
AccountAdapter::setCurrentAccountAvatarFile(const QString& source)
{
    auto futureResult = QtConcurrent::run([this, source]() {
        QPixmap image;
        if (!image.load(source)) {
            qWarning() << "Not a valid image file";
            return;
        }

        QByteArray ba;
        QBuffer bu(&ba);
        bu.open(QIODevice::WriteOnly);
        image.save(&bu, "PNG");
        auto str = QString::fromLocal8Bit(ba.toBase64());
        auto accountId = lrcInstance_->get_currentAccountId();
        lrcInstance_->accountModel().setAvatar(accountId, str);
    });
}

void
AccountAdapter::setCurrentAccountAvatarBase64(const QString& data)
{
    auto futureResult = QtConcurrent::run([this, data]() {
        auto accountId = lrcInstance_->get_currentAccountId();
        lrcInstance_->accountModel().setAvatar(accountId, data);
    });
}

void
AccountAdapter::setDefaultModerator(const QString& accountId,
                                    const QString& peerURI,
                                    const bool& state)
{
    lrcInstance_->accountModel().setDefaultModerator(accountId, peerURI, state);
}

QStringList
AccountAdapter::getDefaultModerators(const QString& accountId)
{
    return lrcInstance_->accountModel().getDefaultModerators(accountId);
}

// KESS TENTATIVE
bool
AccountAdapter::exportToPeer(const QString& accountId, const QString& uri)
{
    return lrcInstance_->accountModel().exportToPeer(accountId, uri);
}

bool
AccountAdapter::exportToFile(const QString& accountId,
                             const QString& path,
                             const QString& password) const
{
    return lrcInstance_->accountModel().exportToFile(accountId, path, password);
}

void
AccountAdapter::setArchivePasswordAsync(const QString& accountID, const QString& password)
{
    auto futureResult = QtConcurrent::run([this, accountID, password] {
        auto config = lrcInstance_->accountModel().getAccountConfig(accountID);
        config.archivePassword = password;
        lrcInstance_->accountModel().setAccountConfig(accountID, config);
    });
}
