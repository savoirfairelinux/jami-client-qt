/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
#include "wizardviewstepmodel.h"
#include "global.h"
#include "api/account.h"

#include <QThreadPool>

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

    connect(&lrcInstance_->accountModel(), &AccountModel::profileUpdated, this, &AccountAdapter::accountStatusChanged);

    connect(systemTray_,
            &SystemTray::countChanged,
            qApp->property("AccountListModel").value<AccountListModel*>(),
            &AccountListModel::updateNotifications);

    // Switch account to the specified index when an account is added.
    connect(this, &AccountAdapter::accountAdded, this, [this](const QString&, int index) { changeAccount(index); });
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
            lrcInstance_->accountModel().setAvatar(accountId, settings["avatar"].toString(), true, 1);
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
                                                          lrcInstance_->accountModel().getAccountList().indexOf(
                                                              accountId));
                                      QObject::disconnect(registeredNameSavedConnection_);
                                  }
                              });

                lrcInstance_->accountModel().registerName(accountId, settings["password"].toString(), registeredName);
            } else {
                Q_EMIT lrcInstance_->accountListChanged();
                Q_EMIT accountAdded(accountId, lrcInstance_->accountModel().getAccountList().indexOf(accountId));
            }
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    QThreadPool::globalInstance()->start([this, settings] {
        lrcInstance_->accountModel().createNewAccount(lrc::api::profile::Type::JAMI,
                                                      {},
                                                      settings["alias"].toString(),
                                                      settings["archivePath"].toString(),
                                                      settings["password"].toString(),
                                                      "");
    });
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
            Q_EMIT accountAdded(accountId, lrcInstance_->accountModel().getAccountList().indexOf(accountId));
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    QThreadPool::globalInstance()->start([this, settings] {
        lrcInstance_->accountModel().createNewAccount(lrc::api::profile::Type::SIP,
                                                      {},
                                                      settings["alias"].toString(),
                                                      settings["archivePath"].toString(),
                                                      "",
                                                      settings["username"].toString());
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

            Q_EMIT accountAdded(accountId, lrcInstance_->accountModel().getAccountList().indexOf(accountId));
            Q_EMIT lrcInstance_->accountListChanged();
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    QThreadPool::globalInstance()->start([this, settings] {
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
AccountAdapter::savePassword(const QString& accountId, const QString& oldPassword, const QString& newPassword)
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
    QThreadPool::globalInstance()->start([this, source]() {
        QPixmap image;
        if (!image.load(source)) {
            qWarning() << "Not a valid image file";
            return;
        }

        auto accountId = lrcInstance_->get_currentAccountId();
        lrcInstance_->accountModel().setAvatar(accountId, source);
    });
}

void
AccountAdapter::setCurrentAccountAvatarBase64(const QString& data)
{
    QThreadPool::globalInstance()->start([this, data]() {
        auto accountId = lrcInstance_->get_currentAccountId();
        lrcInstance_->accountModel().setAvatar(accountId, data, true, 1);
    });
}

void
AccountAdapter::setDefaultModerator(const QString& accountId, const QString& peerURI, const bool& state)
{
    lrcInstance_->accountModel().setDefaultModerator(accountId, peerURI, state);
}

QStringList
AccountAdapter::getDefaultModerators(const QString& accountId)
{
    return lrcInstance_->accountModel().getDefaultModerators(accountId);
}

bool
AccountAdapter::exportToFile(const QString& accountId, const QString& path, const QString& password) const
{
    return lrcInstance_->accountModel().exportToFile(accountId, path, password);
}

void
AccountAdapter::setArchivePasswordAsync(const QString& accountID, const QString& password)
{
    QThreadPool::globalInstance()->start([this, accountID, password] {
        auto config = lrcInstance_->accountModel().getAccountConfig(accountID);
        config.archivePassword = password;
        lrcInstance_->accountModel().setAccountConfig(accountID, config);
    });
}

void
AccountAdapter::startImportAccount()
{
    auto wizardModel = qApp->property("WizardViewStepModel").value<WizardViewStepModel*>();
    wizardModel->set_deviceAuthState(lrc::api::account::DeviceAuthState::INIT);
    wizardModel->set_deviceLinkDetails({});

    // This will create an account with the ARCHIVE_URL configured to start the import process.
    importAccountId_ = lrcInstance_->accountModel().createDeviceImportAccount();
}

void
AccountAdapter::provideAccountAuthentication(const QString& password)
{
    if (importAccountId_.isEmpty()) {
        qWarning() << "No import account to provide password to";
        return;
    }

    auto wizardModel = qApp->property("WizardViewStepModel").value<WizardViewStepModel*>();
    wizardModel->set_deviceAuthState(lrc::api::account::DeviceAuthState::IN_PROGRESS);

    Utils::oneShotConnect(
        &lrcInstance_->accountModel(),
        &lrc::api::AccountModel::accountAdded,
        [this](const QString& accountId) {
            Q_EMIT lrcInstance_->accountListChanged();
            Q_EMIT accountAdded(accountId, lrcInstance_->accountModel().getAccountList().indexOf(accountId));
        },
        this,
        &AccountAdapter::accountCreationFailed);

    connectFailure();

    QThreadPool::globalInstance()->start(
        [this, password] { lrcInstance_->accountModel().provideAccountAuthentication(importAccountId_, password); });
}

QString
AccountAdapter::getImportErrorMessage(QVariantMap details)
{
    QString errorString = details.value("error").toString();
    if (!errorString.isEmpty() && errorString != "none") {
        auto error = lrc::api::account::mapLinkDeviceError(errorString.toStdString());
        return lrc::api::account::getLinkDeviceString(error);
    }

    return "";
}

void
AccountAdapter::cancelImportAccount()
{
    auto wizardModel = qApp->property("WizardViewStepModel").value<WizardViewStepModel*>();
    wizardModel->set_deviceAuthState(lrc::api::account::DeviceAuthState::INIT);
    wizardModel->set_deviceLinkDetails({});

    // Remove the account if it was created
    lrcInstance_->accountModel().removeAccount(importAccountId_);
    importAccountId_.clear();
}
