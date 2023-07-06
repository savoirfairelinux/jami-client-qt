/****************************************************************************
 *    Copyright (C) 2017-2023 Savoir-faire Linux Inc.                       *
 *   Author: Nicolas Jäger <nicolas.jager@savoirfairelinux.com>             *
 *   Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>           *
 *   Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>       *
 *   Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>         *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "api/accountmodel.h"

// new LRC
#include "api/lrc.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"
#include "api/peerdiscoverymodel.h"
#include "api/callmodel.h"
#include "api/codecmodel.h"
#include "api/devicemodel.h"
#include "api/behaviorcontroller.h"
#include "api/datatransfermodel.h"
#include "authority/storagehelper.h"
#include "callbackshandler.h"
#include "database.h"
#include "vcard.h"

// old LRC
#include "api/profile.h"
#include "qtwrapper/conversions_wrap.hpp"

// Dbus
#include "dbus/configurationmanager.h"

// daemon
#include <account_const.h>

// qt
#include <QtGui/QPixmap>
#include <QtGui/QImage>
#include <QtCore/QBuffer>
#include <QJsonDocument>

#include <atomic>

namespace lrc {

using namespace api;

class AccountModelPimpl : public QObject
{
    Q_OBJECT
public:
    AccountModelPimpl(AccountModel& linked,
                      Lrc& lrc,
                      const CallbacksHandler& callbackHandler,
                      const BehaviorController& behaviorController,
                      MigrationCb& willMigrateCb,
                      MigrationCb& didMigrateCb);
    ~AccountModelPimpl();

    using AccountInfoDbMap = std::map<QString, std::pair<account::Info, std::shared_ptr<Database>>>;

    AccountModel& linked;
    Lrc& lrc;
    const CallbacksHandler& callbacksHandler;
    const BehaviorController& behaviorController;
    AccountInfoDbMap accounts;

    // Synchronization tools
    std::atomic_bool username_changed;
    QString new_username;

    /**
     * Add the profile information from an account to the db then add it to accounts.
     * @param accountId
     * @param db an optional migrated database object
     * @note this method get details for an account from the daemon.
     */
    void addToAccounts(const QString& accountId, std::shared_ptr<Database> db = nullptr);

    /**
     * Remove account from accounts list. Emit accountRemoved.
     * @param accountId
     */
    void removeFromAccounts(const QString& accountId);

    /**
     * Sync changes to the accounts list with the lrc.
     */
    void updateAccounts();

    /**
     * Update accountInfo with details from daemon
     * @param account       account to update
     */
    void updateAccountDetails(account::Info& account);

    /**
     * get a modifiable account informations associated to an accountId.
     * @param accountId.
     * @return a account::Info& structure.
     */
    account::Info& getAccountInfo(const QString& accountId);

public Q_SLOTS:

    /**
     * Emit accountStatusChanged.
     * @param accountId
     * @param status
     */
    void slotAccountStatusChanged(const QString& accountID, const api::account::Status status);

    /**
     * Emit exportOnRingEnded.
     * @param accountId
     * @param status
     * @param pin
     */
    void slotExportOnRingEnded(const QString& accountID, int status, const QString& pin);

    /**
     * @param accountId
     * @param details
     */
    void slotAccountDetailsChanged(const QString& accountID, const MapStringString& details);

    /**
     * @param accountId
     * @param details
     */
    void slotVolatileAccountDetailsChanged(const QString& accountID, const MapStringString& details);

    /**
     * Emit nameRegistrationEnded
     * @param accountId
     * @param status
     * @param name
     */
    void slotNameRegistrationEnded(const QString& accountId, int status, const QString& name);

    /**
     * Emit registeredNameFound
     * @param accountId
     * @param status
     * @param address
     * @param name
     */
    void slotRegisteredNameFound(const QString& accountId,
                                 int status,
                                 const QString& address,
                                 const QString& name);

    /**
     * Emit migrationEnded
     * @param accountId
     * @param ok
     */
    void slotMigrationEnded(const QString& accountId, bool ok);

    /**
     * Emit accountProfileReceived
     * @param accountId
     * @param displayName
     * @param userPhoto
     */
    void slotAccountProfileReceived(const QString& accountId,
                                    const QString& displayName,
                                    const QString& userPhoto);

    /**
     * Emit new position
     * @param accountId
     * @param peerId
     * @param body
     * @param timestamp
     * @param daemonId
     */
    void slotNewPosition(const QString& accountId,
                         const QString& peerId,
                         const QString& body,
                         const uint64_t& timestamp,
                         const QString& daemonId) const;
};

AccountModel::AccountModel(Lrc& lrc,
                           const CallbacksHandler& callbacksHandler,
                           const BehaviorController& behaviorController,
                           MigrationCb& willMigrateCb,
                           MigrationCb& didMigrateCb)
    : QObject(nullptr)
    , pimpl_(std::make_unique<AccountModelPimpl>(*this,
                                                 lrc,
                                                 callbacksHandler,
                                                 behaviorController,
                                                 willMigrateCb,
                                                 didMigrateCb))
{}

AccountModel::~AccountModel() {}

QStringList
AccountModel::getAccountList() const
{
    QStringList filteredAccountIds;
    const QStringList accountIds = ConfigurationManager::instance().getAccountList();

    for (auto const& id : accountIds) {
        auto account = pimpl_->accounts.find(id);
        // Do not include accounts flagged for removal
        if (account != pimpl_->accounts.end() && account->second.first.valid)
            filteredAccountIds.push_back(id);
    }

    return filteredAccountIds;
}

void
AccountModel::setAccountEnabled(const QString& accountId, bool enabled) const
{
    auto& accountInfo = pimpl_->getAccountInfo(accountId);
    accountInfo.enabled = enabled;
    ConfigurationManager::instance().sendRegister(accountId, enabled);
}

void
AccountModel::setAccountConfig(const QString& accountId,
                               const account::ConfProperties_t& confProperties) const
{
    auto& accountInfo = pimpl_->getAccountInfo(accountId);
    auto& configurationManager = ConfigurationManager::instance();
    MapStringString details = confProperties.toDetails();
    // Set values from Info. No need to include ID and TYPE. SIP accounts may modify the USERNAME
    // TODO: move these into the ConfProperties_t struct ?
    using namespace libjami::Account;
    details[ConfProperties::ENABLED] = accountInfo.enabled ? QString("true") : QString("false");
    details[ConfProperties::ALIAS] = accountInfo.profileInfo.alias;
    details[ConfProperties::DISPLAYNAME] = accountInfo.profileInfo.alias;
    details[ConfProperties::TYPE] = (accountInfo.profileInfo.type == profile::Type::JAMI)
                                        ? QString(ProtocolNames::RING)
                                        : QString(ProtocolNames::SIP);
    if (accountInfo.profileInfo.type == profile::Type::JAMI) {
        details[ConfProperties::USERNAME] = accountInfo.profileInfo.uri;
    } else if (accountInfo.profileInfo.type == profile::Type::SIP) {
        VectorMapStringString finalCred;

        MapStringString credentials;
        credentials[ConfProperties::USERNAME] = confProperties.username;
        credentials[ConfProperties::PASSWORD] = confProperties.password;
        credentials[ConfProperties::REALM] = confProperties.realm.isEmpty() ? "*"
                                                                            : confProperties.realm;

        auto credentialsVec = confProperties.credentials;
        credentialsVec[0] = credentials;
        for (auto const& i : credentialsVec) {
            QMap<QString, QString> credMap;
            for (auto const& j : i.toStdMap()) {
                credMap[j.first] = j.second;
            }
            finalCred.append(credMap);
        }

        VectorMapStringString oldCredentials = ConfigurationManager::instance().getCredentials(
            accountId);
        if (oldCredentials.empty() || finalCred.empty()
            || oldCredentials[0][ConfProperties::PASSWORD] != finalCred[0][ConfProperties::PASSWORD]
            || oldCredentials[0][ConfProperties::REALM] != finalCred[0][ConfProperties::REALM]
            || oldCredentials[0][ConfProperties::USERNAME] != finalCred[0][ConfProperties::USERNAME])
            ConfigurationManager::instance().setCredentials(accountId, finalCred);
        details[ConfProperties::USERNAME] = confProperties.username;
        accountInfo.confProperties.credentials.swap(credentialsVec);
    }
    configurationManager.setAccountDetails(accountId, details);
}

account::ConfProperties_t
AccountModel::getAccountConfig(const QString& accountId) const
{
    return getAccountInfo(accountId).confProperties;
}

void
AccountModel::setAlias(const QString& accountId, const QString& alias, bool save)
{
    auto& accountInfo = pimpl_->getAccountInfo(accountId);
    if (accountInfo.profileInfo.alias == alias)
        return;
    accountInfo.profileInfo.alias = alias;

    if (save)
        authority::storage::createOrUpdateProfile(accountInfo.id, accountInfo.profileInfo);
    Q_EMIT profileUpdated(accountId);
}

void
AccountModel::setAvatar(const QString& accountId, const QString& avatar, bool save)
{
    auto& accountInfo = pimpl_->getAccountInfo(accountId);
    if (accountInfo.profileInfo.avatar == avatar)
        return;
    accountInfo.profileInfo.avatar = avatar;

    if (save)
        authority::storage::createOrUpdateProfile(accountInfo.id, accountInfo.profileInfo);
    Q_EMIT profileUpdated(accountId);
}

bool
AccountModel::registerName(const QString& accountId,
                           const QString& password,
                           const QString& username)
{
    return ConfigurationManager::instance().registerName(accountId, password, username);
}

bool
AccountModel::exportToFile(const QString& accountId,
                           const QString& path,
                           const QString& password) const
{
    return ConfigurationManager::instance().exportToFile(accountId, path, password);
}

bool
AccountModel::exportOnRing(const QString& accountId, const QString& password) const
{
    return ConfigurationManager::instance().exportOnRing(accountId, password);
}

void
AccountModel::removeAccount(const QString& accountId) const
{
    auto account = pimpl_->accounts.find(accountId);
    if (account == pimpl_->accounts.end()) {
        return;
    }

    // Close db here for its removal
    account->second.second->close();
    ConfigurationManager::instance().removeAccount(accountId);
}

bool
AccountModel::changeAccountPassword(const QString& accountId,
                                    const QString& currentPassword,
                                    const QString& newPassword) const
{
    return ConfigurationManager::instance().changeAccountPassword(accountId,
                                                                  currentPassword,
                                                                  newPassword);
}

const account::Info&
AccountModel::getAccountInfo(const QString& accountId) const
{
    auto accountInfo = pimpl_->accounts.find(accountId);
    if (accountInfo == pimpl_->accounts.end())
        throw std::out_of_range("AccountModel::getAccountInfo, can't find "
                                + accountId.toStdString());

    return accountInfo->second.first;
}

AccountModelPimpl::AccountModelPimpl(AccountModel& linked,
                                     Lrc& lrc,
                                     const CallbacksHandler& callbacksHandler,
                                     const BehaviorController& behaviorController,
                                     MigrationCb& willMigrateCb,
                                     MigrationCb& didMigrateCb)
    : linked(linked)
    , lrc {lrc}
    , behaviorController(behaviorController)
    , callbacksHandler(callbacksHandler)
    , username_changed(false)
{
    const QStringList accountIds = ConfigurationManager::instance().getAccountList();

    // NOTE: If the daemon is down, but dbus answered, id can contains
    // "Remote peer disconnected", "The name is not activable", etc.
    // So avoid to migrate useless directories.
    for (auto& id : accountIds)
        if (id.indexOf(" ") != -1) {
            qWarning() << "Invalid dbus answer. Daemon not running";
            return;
        }

    auto accountDbs = authority::storage::migrateIfNeeded(accountIds, willMigrateCb, didMigrateCb);
    for (const auto& id : accountIds) {
        addToAccounts(id, accountDbs.at(accountIds.indexOf(id)));
    }

    connect(&callbacksHandler,
            &CallbacksHandler::accountsChanged,
            this,
            &AccountModelPimpl::updateAccounts);
    connect(&callbacksHandler,
            &CallbacksHandler::accountStatusChanged,
            this,
            &AccountModelPimpl::slotAccountStatusChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::accountDetailsChanged,
            this,
            &AccountModelPimpl::slotAccountDetailsChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::volatileAccountDetailsChanged,
            this,
            &AccountModelPimpl::slotVolatileAccountDetailsChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::exportOnRingEnded,
            this,
            &AccountModelPimpl::slotExportOnRingEnded);
    connect(&callbacksHandler,
            &CallbacksHandler::nameRegistrationEnded,
            this,
            &AccountModelPimpl::slotNameRegistrationEnded);
    connect(&callbacksHandler,
            &CallbacksHandler::registeredNameFound,
            this,
            &AccountModelPimpl::slotRegisteredNameFound);
    connect(&callbacksHandler,
            &CallbacksHandler::migrationEnded,
            this,
            &AccountModelPimpl::slotMigrationEnded);
    connect(&callbacksHandler,
            &CallbacksHandler::accountProfileReceived,
            this,
            &AccountModelPimpl::slotAccountProfileReceived);
    connect(&callbacksHandler,
            &CallbacksHandler::newPosition,
            this,
            &AccountModelPimpl::slotNewPosition);
}

AccountModelPimpl::~AccountModelPimpl() {}

void
AccountModelPimpl::updateAccounts()
{
    qDebug() << "Syncing lrc accounts list with the daemon";
    ConfigurationManagerInterface& configurationManager = ConfigurationManager::instance();
    QStringList accountIds = configurationManager.getAccountList();

    // Detect removed accounts
    QStringList toBeRemoved;
    for (auto& it : accounts) {
        auto& accountInfo = it.second.first;
        if (!accountIds.contains(accountInfo.id)) {
            qDebug() << QString("detected account removal %1").arg(accountInfo.id);
            toBeRemoved.push_back(accountInfo.id);
        }
    }

    for (auto it = toBeRemoved.begin(); it != toBeRemoved.end(); ++it) {
        removeFromAccounts(*it);
    }

    // Detect new accounts
    for (auto& id : accountIds) {
        auto account = accounts.find(id);
        // NOTE: If the daemon is down, but dbus answered, id can contains
        // "Remote peer disconnected", "The name is not activable", etc.
        // So avoid to create useless directories.
        if (account == accounts.end() && id.indexOf(" ") == -1) {
            qWarning() << QString("detected new account %1").arg(id);
            addToAccounts(id);
            auto updatedAccount = accounts.find(id);
            if (updatedAccount == accounts.end()) {
                return;
            }
            if (updatedAccount->second.first.profileInfo.type == profile::Type::SIP) {
                // NOTE: At this point, a SIP account is ready, but not a Ring
                // account. Indeed, the keys are not generated at this point.
                // See slotAccountStatusChanged for more details.
                Q_EMIT linked.accountAdded(id);
            }
        }
    }
}

void
AccountModelPimpl::updateAccountDetails(account::Info& accountInfo)
{
    // Fill account::Info struct with details from daemon
    MapStringString details = ConfigurationManager::instance().getAccountDetails(accountInfo.id);
    accountInfo.fromDetails(details);

    // Fill account::Info::confProperties credentials
    VectorMapStringString credGet = ConfigurationManager::instance().getCredentials(accountInfo.id);
    VectorMapStringString credToStore;
    for (auto const& i : std::vector<MapStringString>(credGet.begin(), credGet.end())) {
        MapStringString credMap;
        for (auto const& j : i.toStdMap()) {
            credMap[j.first] = j.second;
        }
        credToStore.push_back(credMap);
    }

    accountInfo.confProperties.credentials.swap(credToStore);
}

account::Info&
AccountModelPimpl::getAccountInfo(const QString& accountId)
{
    auto account = accounts.find(accountId);
    if (account == accounts.end()) {
        throw std::out_of_range("AccountModelPimpl::getAccountInfo, can't find "
                                + accountId.toStdString());
    }
    return account->second.first;
}

void
AccountModelPimpl::slotAccountStatusChanged(const QString& accountID,
                                            const api::account::Status status)
{
    if (status == api::account::Status::INVALID) {
        Q_EMIT linked.invalidAccountDetected(accountID);
        return;
    }
    auto it = accounts.find(accountID);

    // If account is not in the map yet, don't add it, it is updateAccounts's job
    if (it == accounts.end()) {
        return;
    }

    auto& accountInfo = it->second.first;

    if (accountInfo.profileInfo.type != profile::Type::SIP) {
        if (status != api::account::Status::INITIALIZING
            && accountInfo.status == api::account::Status::INITIALIZING) {
            // Detect when a new account is generated (keys are ready). During
            // the generation, a Ring account got the "INITIALIZING" status.
            // When keys are generated, the status will change.
            // The account is already added and initialized. Just update details from daemon
            updateAccountDetails(accountInfo);
            // This will load swarms as the account was not loaded before.
            accountInfo.conversationModel->initConversations();
            Q_EMIT linked.accountAdded(accountID);
        } else if (!accountInfo.profileInfo.uri.isEmpty()) {
            accountInfo.status = status;
            Q_EMIT linked.accountStatusChanged(accountID);
        }
    } else {
        accountInfo.status = status;
        Q_EMIT linked.accountStatusChanged(accountID);
    }
}

void
AccountModelPimpl::slotAccountDetailsChanged(const QString& accountId,
                                             const MapStringString& details)
{
    auto account = accounts.find(accountId);
    if (account == accounts.end()) {
        throw std::out_of_range("AccountModelPimpl::slotAccountDetailsChanged, can't find "
                                + accountId.toStdString());
    }
    auto& accountInfo = account->second.first;
    accountInfo.fromDetails(details);
    if (username_changed) {
        username_changed = false;
        accountInfo.registeredName = new_username;
        Q_EMIT linked.profileUpdated(accountId);
    }
    // TODO: Remove accountStatusChanged here.
    Q_EMIT linked.accountStatusChanged(accountId);
    Q_EMIT linked.accountDetailsChanged(accountId);
}

void
AccountModelPimpl::slotVolatileAccountDetailsChanged(const QString& accountId,
                                                     const MapStringString& details)
{
    auto account = accounts.find(accountId);
    if (account == accounts.end()) {
        qWarning() << "AccountModelPimpl::slotVolatileAccountDetailsChanged, can't find "
                   << accountId;
        return;
    }
    auto& accountInfo = account->second.first;

    auto new_usernameIt = details.find(libjami::Account::VolatileProperties::REGISTERED_NAME);
    if (new_usernameIt == details.end())
        return;
    accountInfo.registeredName = new_usernameIt.value();

    auto new_deviceId = details.find(libjami::Account::ConfProperties::DEVICE_ID);
    if (new_deviceId != details.end())
        accountInfo.confProperties.deviceId = new_deviceId.value();

    Q_EMIT linked.profileUpdated(accountId);
}

void
AccountModelPimpl::slotExportOnRingEnded(const QString& accountID, int status, const QString& pin)
{
    account::ExportOnRingStatus convertedStatus = account::ExportOnRingStatus::INVALID;
    switch (status) {
    case 0:
        convertedStatus = account::ExportOnRingStatus::SUCCESS;
        break;
    case 1:
        convertedStatus = account::ExportOnRingStatus::WRONG_PASSWORD;
        break;
    case 2:
        convertedStatus = account::ExportOnRingStatus::NETWORK_ERROR;
        break;
    default:
        break;
    }
    Q_EMIT linked.exportOnRingEnded(accountID, convertedStatus, pin);
}

void
AccountModelPimpl::slotNameRegistrationEnded(const QString& accountId,
                                             int status,
                                             const QString& name)
{
    account::RegisterNameStatus convertedStatus = account::RegisterNameStatus::INVALID;
    switch (status) {
    case 0: {
        convertedStatus = account::RegisterNameStatus::SUCCESS;
        auto account = accounts.find(accountId);
        if (account != accounts.end() && account->second.first.registeredName.isEmpty()) {
            auto conf = linked.getAccountConfig(accountId);
            username_changed = true;
            new_username = name;
            linked.setAccountConfig(accountId, conf);
        }
        break;
    }
    case 1:
        convertedStatus = account::RegisterNameStatus::WRONG_PASSWORD;
        break;
    case 2:
        convertedStatus = account::RegisterNameStatus::INVALID_NAME;
        break;
    case 3:
        convertedStatus = account::RegisterNameStatus::ALREADY_TAKEN;
        break;
    case 4:
        convertedStatus = account::RegisterNameStatus::NETWORK_ERROR;
        break;
    default:
        break;
    }
    Q_EMIT linked.nameRegistrationEnded(accountId, convertedStatus, name);
}

void
AccountModelPimpl::slotRegisteredNameFound(const QString& accountId,
                                           int status,
                                           const QString& address,
                                           const QString& name)
{
    account::LookupStatus convertedStatus = account::LookupStatus::INVALID;
    switch (status) {
    case 0:
        convertedStatus = account::LookupStatus::SUCCESS;
        break;
    case 1:
        convertedStatus = account::LookupStatus::INVALID_NAME;
        break;
    case 2:
        convertedStatus = account::LookupStatus::NOT_FOUND;
        break;
    case 3:
        convertedStatus = account::LookupStatus::ERROR;
        break;
    default:
        break;
    }
    Q_EMIT linked.registeredNameFound(accountId, convertedStatus, address, name);
}

void
AccountModelPimpl::slotMigrationEnded(const QString& accountId, bool ok)
{
    if (ok) {
        auto it = accounts.find(accountId);
        if (it == accounts.end()) {
            addToAccounts(accountId);
            return;
        }
        auto& accountInfo = it->second.first;
        MapStringString details = ConfigurationManager::instance().getAccountDetails(accountId);
        accountInfo.fromDetails(details);
    }
    Q_EMIT linked.migrationEnded(accountId, ok);
}

void
AccountModelPimpl::slotAccountProfileReceived(const QString& accountId,
                                              const QString& displayName,
                                              const QString& userPhoto)
{
    auto account = accounts.find(accountId);
    if (account == accounts.end())
        return;
    auto& accountInfo = account->second.first;
    accountInfo.profileInfo.avatar = userPhoto;
    accountInfo.profileInfo.alias = displayName;

    authority::storage::createOrUpdateProfile(accountInfo.id, accountInfo.profileInfo);

    Q_EMIT linked.profileUpdated(accountId);
}

void
AccountModelPimpl::slotNewPosition(const QString& accountId,
                                   const QString& peerId,
                                   const QString& body,
                                   const uint64_t& timestamp,
                                   const QString& daemonId) const
{
    Q_EMIT linked.newPosition(accountId, peerId, body, timestamp, daemonId);
}

void
AccountModelPimpl::addToAccounts(const QString& accountId, std::shared_ptr<Database> db)
{
    if (db == nullptr) {
        try {
            auto appPath = authority::storage::getPath();
            auto dbName = accountId + "/history";
            db = DatabaseFactory::create<Database>(dbName, appPath);
            // create the profiles path if necessary
            QDir profilesDir(appPath + accountId + "/profiles");
            if (!profilesDir.exists()) {
                profilesDir.mkpath(".");
            }
        } catch (const std::runtime_error& e) {
            qWarning() << e.what();
            return;
        }
    }

    auto it = accounts.emplace(accountId, std::make_pair(account::Info(), db));

    if (!it.second) {
        qWarning("failed to add new account: id already present in map");
        return;
    }

    // Init profile
    account::Info& newAccInfo = (it.first)->second.first;
    newAccInfo.id = accountId;
    newAccInfo.profileInfo.avatar = authority::storage::getAccountAvatar(accountId);
    updateAccountDetails(newAccInfo);

    // Init models for this account
    newAccInfo.accountModel = &linked;
    newAccInfo.callModel = std::make_unique<CallModel>(newAccInfo,
                                                       lrc,
                                                       callbacksHandler,
                                                       behaviorController);
    newAccInfo.contactModel = std::make_unique<ContactModel>(newAccInfo,
                                                             *db,
                                                             callbacksHandler,
                                                             behaviorController);
    newAccInfo.conversationModel = std::make_unique<ConversationModel>(newAccInfo,
                                                                       lrc,
                                                                       *db,
                                                                       callbacksHandler,
                                                                       behaviorController);
    newAccInfo.peerDiscoveryModel = std::make_unique<PeerDiscoveryModel>(callbacksHandler,
                                                                         accountId);
    newAccInfo.deviceModel = std::make_unique<DeviceModel>(newAccInfo, callbacksHandler);
    newAccInfo.codecModel = std::make_unique<CodecModel>(newAccInfo, callbacksHandler);
    newAccInfo.dataTransferModel = std::make_unique<DataTransferModel>();
}

void
AccountModelPimpl::removeFromAccounts(const QString& accountId)
{
    /* Update db before waiting for the client to stop using the structs is fine
       as long as we don't free anything */
    auto account = accounts.find(accountId);
    if (account == accounts.end()) {
        return;
    }
    auto& accountInfo = account->second.first;
    if (accountInfo.profileInfo.type == profile::Type::SIP) {
        auto accountDir = QDir(authority::storage::getPath() + accountId);
        accountDir.removeRecursively();
    }

    /* Inform client about account removal. Do *not* free account structures
       before we are sure that the client stopped using it, otherwise we might
       get into use-after-free troubles. */
    accountInfo.valid = false;
    Q_EMIT linked.accountRemoved(accountId);

    // Now we can free them
    accounts.erase(accountId);
}

void
account::Info::fromDetails(const MapStringString& details)
{
    using namespace libjami::Account;
    const MapStringString volatileDetails = ConfigurationManager::instance()
                                                .getVolatileAccountDetails(id);

    // General
    if (details[ConfProperties::TYPE] != "")
        profileInfo.type = details[ConfProperties::TYPE] == QString(ProtocolNames::RING)
                               ? profile::Type::JAMI
                               : profile::Type::SIP;
    registeredName = profileInfo.type == profile::Type::JAMI
                         ? volatileDetails[VolatileProperties::REGISTERED_NAME]
                         : "";
    profileInfo.alias = details[ConfProperties::DISPLAYNAME];
    enabled = toBool(details[ConfProperties::ENABLED]);
    status = lrc::api::account::to_status(
        volatileDetails[libjami::Account::ConfProperties::Registration::STATUS]);
    confProperties.mailbox = details[ConfProperties::MAILBOX];
    confProperties.dtmfType = details[ConfProperties::DTMF_TYPE];
    confProperties.autoAnswer = toBool(details[ConfProperties::AUTOANSWER]);
    confProperties.sendReadReceipt = toBool(details[ConfProperties::SENDREADRECEIPT]);
    confProperties.isRendezVous = toBool(details[ConfProperties::ISRENDEZVOUS]);
    confProperties.activeCallLimit = toInt(details[ConfProperties::ACTIVE_CALL_LIMIT]);
    confProperties.hostname = details[ConfProperties::HOSTNAME];
    profileInfo.uri = (profileInfo.type == profile::Type::JAMI
                       and details[ConfProperties::USERNAME].contains("ring:"))
                          ? QString(details[ConfProperties::USERNAME]).remove(QString("ring:"))
                          : details[ConfProperties::USERNAME];
    confProperties.username = details[ConfProperties::USERNAME];
    confProperties.routeset = details[ConfProperties::ROUTE];
    confProperties.password = details[ConfProperties::PASSWORD];
    confProperties.realm = details[ConfProperties::REALM];
    confProperties.localInterface = details[ConfProperties::LOCAL_INTERFACE];
    confProperties.deviceId = volatileDetails[ConfProperties::DEVICE_ID];
    confProperties.deviceName = details[ConfProperties::DEVICE_NAME];
    confProperties.publishedSameAsLocal = toBool(details[ConfProperties::PUBLISHED_SAMEAS_LOCAL]);
    confProperties.localPort = toInt(details[ConfProperties::LOCAL_PORT]);
    confProperties.publishedPort = toInt(details[ConfProperties::PUBLISHED_PORT]);
    confProperties.registrationExpire = toInt(details[ConfProperties::Registration::EXPIRE]);
    confProperties.publishedAddress = details[ConfProperties::PUBLISHED_ADDRESS];
    confProperties.userAgent = details[ConfProperties::USER_AGENT];
    confProperties.upnpEnabled = toBool(details[ConfProperties::UPNP_ENABLED]);
    confProperties.hasCustomUserAgent = toBool(details[ConfProperties::HAS_CUSTOM_USER_AGENT]);
    confProperties.allowIncoming = toBool(details[ConfProperties::ALLOW_CERT_FROM_HISTORY])
                                   | toBool(details[ConfProperties::ALLOW_CERT_FROM_CONTACT])
                                   | toBool(details[ConfProperties::ALLOW_CERT_FROM_TRUSTED]);
    confProperties.allowIPAutoRewrite = toBool(details[ConfProperties::ACCOUNT_IP_AUTO_REWRITE]);
    confProperties.archivePassword = details[ConfProperties::ARCHIVE_PASSWORD];
    confProperties.archiveHasPassword = toBool(details[ConfProperties::ARCHIVE_HAS_PASSWORD]);
    confProperties.archivePath = details[ConfProperties::ARCHIVE_PATH];
    confProperties.archivePin = details[ConfProperties::ARCHIVE_PIN];
    confProperties.proxyEnabled = toBool(details[ConfProperties::PROXY_ENABLED]);
    confProperties.proxyServer = details[ConfProperties::PROXY_SERVER];
    confProperties.proxyPushToken = details[ConfProperties::PROXY_PUSH_TOKEN];
    confProperties.peerDiscovery = toBool(details[ConfProperties::DHT_PEER_DISCOVERY]);
    confProperties.accountDiscovery = toBool(details[ConfProperties::ACCOUNT_PEER_DISCOVERY]);
    confProperties.accountPublish = toBool(details[ConfProperties::ACCOUNT_PUBLISH]);
    confProperties.keepAliveEnabled = toBool(details[ConfProperties::KEEP_ALIVE_ENABLED]);
    confProperties.bootstrapListUrl = QString(details[ConfProperties::BOOTSTRAP_LIST_URL]);
    confProperties.dhtProxyListUrl = QString(details[ConfProperties::DHT_PROXY_LIST_URL]);
    confProperties.defaultModerators = QString(details[ConfProperties::DEFAULT_MODERATORS]);
    confProperties.localModeratorsEnabled = toBool(
        details[ConfProperties::LOCAL_MODERATORS_ENABLED]);
    // Audio
    confProperties.Audio.audioPortMax = toInt(details[ConfProperties::Audio::PORT_MAX]);
    confProperties.Audio.audioPortMin = toInt(details[ConfProperties::Audio::PORT_MIN]);
    // Video
    confProperties.Video.videoEnabled = toBool(details[ConfProperties::Video::ENABLED]);
    confProperties.Video.videoPortMax = toInt(details[ConfProperties::Video::PORT_MAX]);
    confProperties.Video.videoPortMin = toInt(details[ConfProperties::Video::PORT_MIN]);
    // STUN
    confProperties.STUN.server = details[ConfProperties::STUN::SERVER];
    confProperties.STUN.enable = toBool(details[ConfProperties::STUN::ENABLED]);
    // TURN
    confProperties.TURN.server = details[ConfProperties::TURN::SERVER];
    confProperties.TURN.enable = toBool(details[ConfProperties::TURN::ENABLED]);
    confProperties.TURN.username = details[ConfProperties::TURN::SERVER_UNAME];
    confProperties.TURN.password = details[ConfProperties::TURN::SERVER_PWD];
    confProperties.TURN.realm = details[ConfProperties::TURN::SERVER_REALM];
    // Presence
    confProperties.Presence.presencePublishSupported = toBool(
        details[ConfProperties::Presence::SUPPORT_PUBLISH]);
    confProperties.Presence.presenceSubscribeSupported = toBool(
        details[ConfProperties::Presence::SUPPORT_SUBSCRIBE]);
    confProperties.Presence.presenceEnabled = toBool(details[ConfProperties::Presence::ENABLED]);
    // Ringtone
    confProperties.Ringtone.ringtonePath = details[ConfProperties::Ringtone::PATH];
    confProperties.Ringtone.ringtoneEnabled = toBool(details[ConfProperties::Ringtone::ENABLED]);
    // SRTP
    confProperties.SRTP.keyExchange = details[ConfProperties::SRTP::KEY_EXCHANGE].isEmpty()
                                          ? account::KeyExchangeProtocol::NONE
                                          : account::KeyExchangeProtocol::SDES;
    confProperties.SRTP.enable = toBool(details[ConfProperties::SRTP::ENABLED]);
    // TLS
    confProperties.TLS.listenerPort = toInt(details[ConfProperties::TLS::LISTENER_PORT]);
    confProperties.TLS.enable = details[ConfProperties::TYPE] == QString(ProtocolNames::RING)
                                    ? true
                                    : toBool(details[ConfProperties::TLS::ENABLED]);
    confProperties.TLS.port = toInt(details[ConfProperties::TLS::PORT]);
    confProperties.TLS.certificateListFile = details[ConfProperties::TLS::CA_LIST_FILE];
    confProperties.TLS.certificateFile = details[ConfProperties::TLS::CERTIFICATE_FILE];
    confProperties.TLS.privateKeyFile = details[ConfProperties::TLS::PRIVATE_KEY_FILE];
    confProperties.TLS.password = details[ConfProperties::TLS::PASSWORD];
    confProperties.TLS.verifyServer = toBool(details[ConfProperties::TLS::VERIFY_SERVER]);
    confProperties.TLS.verifyClient = toBool(details[ConfProperties::TLS::VERIFY_CLIENT]);
    confProperties.TLS.requireClientCertificate = toBool(
        details[ConfProperties::TLS::REQUIRE_CLIENT_CERTIFICATE]);
    confProperties.TLS.disableSecureDlgCheck = toBool(
        details[ConfProperties::TLS::DISABLE_SECURE_DLG_CHECK]);
    // DHT
    confProperties.DHT.port = toInt(details[ConfProperties::DHT::PORT]);
    confProperties.DHT.PublicInCalls = toBool(details[ConfProperties::DHT::PUBLIC_IN_CALLS]);
    confProperties.DHT.AllowFromTrusted = toBool(details[ConfProperties::DHT::ALLOW_FROM_TRUSTED]);
    // RingNS
    confProperties.RingNS.uri = details[ConfProperties::RingNS::URI];
    confProperties.RingNS.account = details[ConfProperties::RingNS::ACCOUNT];
    // Jams
    confProperties.managerUri = details[ConfProperties::MANAGER_URI];
    confProperties.managerUsername = details[ConfProperties::MANAGER_USERNAME];
    // uiCustomization
    QJsonDocument doc = QJsonDocument::fromJson(details[ConfProperties::UI_CUSTOMIZATION].toUtf8());
    if (!doc.isNull() && doc.isObject()) {
        confProperties.uiCustomization = doc.object();
    }
}

MapStringString
account::ConfProperties_t::toDetails() const
{
    using namespace libjami::Account;
    MapStringString details;
    // General
    details[ConfProperties::MAILBOX] = this->mailbox;
    details[ConfProperties::DTMF_TYPE] = this->dtmfType;
    details[ConfProperties::AUTOANSWER] = toQString(this->autoAnswer);
    details[ConfProperties::SENDREADRECEIPT] = toQString(this->sendReadReceipt);
    details[ConfProperties::ISRENDEZVOUS] = toQString(this->isRendezVous);
    details[ConfProperties::ACTIVE_CALL_LIMIT] = toQString(this->activeCallLimit);
    details[ConfProperties::HOSTNAME] = this->hostname;
    details[ConfProperties::ROUTE] = this->routeset;
    details[ConfProperties::PASSWORD] = this->password;
    details[ConfProperties::REALM] = this->realm;
    details[ConfProperties::DEVICE_ID] = this->deviceId;
    details[ConfProperties::DEVICE_NAME] = this->deviceName;
    details[ConfProperties::LOCAL_INTERFACE] = this->localInterface;
    details[ConfProperties::PUBLISHED_SAMEAS_LOCAL] = toQString(this->publishedSameAsLocal);
    details[ConfProperties::LOCAL_PORT] = toQString(this->localPort);
    details[ConfProperties::PUBLISHED_PORT] = toQString(this->publishedPort);
    details[ConfProperties::Registration::EXPIRE] = toQString(this->registrationExpire);
    details[ConfProperties::PUBLISHED_ADDRESS] = this->publishedAddress;
    details[ConfProperties::USER_AGENT] = this->userAgent;
    details[ConfProperties::UPNP_ENABLED] = toQString(this->upnpEnabled);
    details[ConfProperties::HAS_CUSTOM_USER_AGENT] = toQString(this->hasCustomUserAgent);
    details[ConfProperties::ALLOW_CERT_FROM_HISTORY] = toQString(this->allowIncoming);
    details[ConfProperties::ALLOW_CERT_FROM_CONTACT] = toQString(this->allowIncoming);
    details[ConfProperties::ALLOW_CERT_FROM_TRUSTED] = toQString(this->allowIncoming);
    details[ConfProperties::ACCOUNT_IP_AUTO_REWRITE] = toQString(this->allowIPAutoRewrite);
    details[ConfProperties::ARCHIVE_PASSWORD] = this->archivePassword;
    details[ConfProperties::ARCHIVE_HAS_PASSWORD] = toQString(this->archiveHasPassword);
    details[ConfProperties::ARCHIVE_PATH] = this->archivePath;
    details[ConfProperties::ARCHIVE_PIN] = this->archivePin;
    // ConfProperties::DEVICE_NAME name is set with DeviceModel interface
    details[ConfProperties::PROXY_ENABLED] = toQString(this->proxyEnabled);
    details[ConfProperties::PROXY_SERVER] = this->proxyServer;
    details[ConfProperties::PROXY_PUSH_TOKEN] = this->proxyPushToken;
    details[ConfProperties::DHT_PEER_DISCOVERY] = toQString(this->peerDiscovery);
    details[ConfProperties::ACCOUNT_PEER_DISCOVERY] = toQString(this->accountDiscovery);
    details[ConfProperties::ACCOUNT_PUBLISH] = toQString(this->accountPublish);
    details[ConfProperties::KEEP_ALIVE_ENABLED] = toQString(this->keepAliveEnabled);
    details[ConfProperties::BOOTSTRAP_LIST_URL] = this->bootstrapListUrl;
    details[ConfProperties::DHT_PROXY_LIST_URL] = this->dhtProxyListUrl;
    details[ConfProperties::DEFAULT_MODERATORS] = this->defaultModerators;
    details[ConfProperties::LOCAL_MODERATORS_ENABLED] = toQString(this->localModeratorsEnabled);
    // Audio
    details[ConfProperties::Audio::PORT_MAX] = toQString(this->Audio.audioPortMax);
    details[ConfProperties::Audio::PORT_MIN] = toQString(this->Audio.audioPortMin);
    // Video
    details[ConfProperties::Video::ENABLED] = toQString(this->Video.videoEnabled);
    details[ConfProperties::Video::PORT_MAX] = toQString(this->Video.videoPortMax);
    details[ConfProperties::Video::PORT_MIN] = toQString(this->Video.videoPortMin);
    // STUN
    details[ConfProperties::STUN::SERVER] = this->STUN.server;
    details[ConfProperties::STUN::ENABLED] = toQString(this->STUN.enable);
    // TURN
    details[ConfProperties::TURN::SERVER] = this->TURN.server;
    details[ConfProperties::TURN::ENABLED] = toQString(this->TURN.enable);
    details[ConfProperties::TURN::SERVER_UNAME] = this->TURN.username;
    details[ConfProperties::TURN::SERVER_PWD] = this->TURN.password;
    details[ConfProperties::TURN::SERVER_REALM] = this->TURN.realm;
    // Presence
    details[ConfProperties::Presence::SUPPORT_PUBLISH] = toQString(
        this->Presence.presencePublishSupported);
    details[ConfProperties::Presence::SUPPORT_SUBSCRIBE] = toQString(
        this->Presence.presenceSubscribeSupported);
    details[ConfProperties::Presence::ENABLED] = toQString(this->Presence.presenceEnabled);
    // Ringtone
    details[ConfProperties::Ringtone::PATH] = this->Ringtone.ringtonePath;
    details[ConfProperties::Ringtone::ENABLED] = toQString(this->Ringtone.ringtoneEnabled);
    // SRTP
    details[ConfProperties::SRTP::KEY_EXCHANGE] = this->SRTP.keyExchange
                                                          == account::KeyExchangeProtocol::NONE
                                                      ? ""
                                                      : "sdes";
    details[ConfProperties::SRTP::ENABLED] = toQString(this->SRTP.enable);
    // TLS
    details[ConfProperties::TLS::LISTENER_PORT] = toQString(this->TLS.listenerPort);
    details[ConfProperties::TLS::ENABLED] = toQString(this->TLS.enable);
    details[ConfProperties::TLS::PORT] = toQString(this->TLS.port);
    details[ConfProperties::TLS::CA_LIST_FILE] = this->TLS.certificateListFile;
    details[ConfProperties::TLS::CERTIFICATE_FILE] = this->TLS.certificateFile;
    details[ConfProperties::TLS::PRIVATE_KEY_FILE] = this->TLS.privateKeyFile;
    details[ConfProperties::TLS::PASSWORD] = this->TLS.password;
    details[ConfProperties::TLS::VERIFY_SERVER] = toQString(this->TLS.verifyServer);
    details[ConfProperties::TLS::VERIFY_CLIENT] = toQString(this->TLS.verifyClient);
    details[ConfProperties::TLS::REQUIRE_CLIENT_CERTIFICATE] = toQString(
        this->TLS.requireClientCertificate);
    details[ConfProperties::TLS::DISABLE_SECURE_DLG_CHECK] = toQString(
        this->TLS.disableSecureDlgCheck);
    // DHT
    details[ConfProperties::DHT::PORT] = toQString(this->DHT.port);
    details[ConfProperties::DHT::PUBLIC_IN_CALLS] = toQString(this->DHT.PublicInCalls);
    details[ConfProperties::DHT::ALLOW_FROM_TRUSTED] = toQString(this->DHT.AllowFromTrusted);
    // RingNS
    details[ConfProperties::RingNS::URI] = this->RingNS.uri;
    details[ConfProperties::RingNS::ACCOUNT] = this->RingNS.account;
    // Manager
    details[ConfProperties::MANAGER_URI] = this->managerUri;
    details[ConfProperties::MANAGER_USERNAME] = this->managerUsername;
    // UI Customization
    QJsonDocument doc(this->uiCustomization);
    details[ConfProperties::UI_CUSTOMIZATION] = doc.toJson(QJsonDocument::Compact);

    return details;
}

QString
AccountModel::createNewAccount(profile::Type type,
                               const QString& displayName,
                               const QString& archivePath,
                               const QString& password,
                               const QString& pin,
                               const QString& uri,
                               const MapStringString& config)
{
    MapStringString details = type == profile::Type::SIP
                                  ? ConfigurationManager::instance().getAccountTemplate("SIP")
                                  : ConfigurationManager::instance().getAccountTemplate("RING");
    using namespace libjami::Account;
    details[ConfProperties::TYPE] = type == profile::Type::SIP ? "SIP" : "RING";
    details[ConfProperties::DISPLAYNAME] = displayName;
    details[ConfProperties::ALIAS] = displayName;
    details[ConfProperties::UPNP_ENABLED] = "true";
    details[ConfProperties::ARCHIVE_PASSWORD] = password;
    details[ConfProperties::ARCHIVE_PIN] = pin;
    details[ConfProperties::ARCHIVE_PATH] = archivePath;
    if (type == profile::Type::SIP)
        details[ConfProperties::USERNAME] = uri;
    if (!config.isEmpty()) {
        for (MapStringString::const_iterator it = config.begin(); it != config.end(); it++) {
            details[it.key()] = it.value();
        }
    }

    QString accountId = ConfigurationManager::instance().addAccount(details);
    return accountId;
}

QString
AccountModel::connectToAccountManager(const QString& username,
                                      const QString& password,
                                      const QString& serverUri,
                                      const MapStringString& config)
{
    MapStringString details = ConfigurationManager::instance().getAccountTemplate("RING");
    using namespace libjami::Account;
    details[ConfProperties::TYPE] = "RING";
    details[ConfProperties::MANAGER_URI] = serverUri;
    details[ConfProperties::MANAGER_USERNAME] = username;
    details[ConfProperties::ARCHIVE_PASSWORD] = password;
    if (!config.isEmpty()) {
        for (MapStringString::const_iterator it = config.begin(); it != config.end(); it++) {
            details[it.key()] = it.value();
        }
    }

    QString accountId = ConfigurationManager::instance().addAccount(details);
    return accountId;
}

void
AccountModel::setTopAccount(const QString& accountId)
{
    bool found = false;
    QString order = {};

    const QStringList accountIds = ConfigurationManager::instance().getAccountList();
    for (auto& id : accountIds) {
        if (id == accountId) {
            found = true;
        } else {
            order += id + "/";
        }
    }
    if (found) {
        order = accountId + "/" + order;
    }
    ConfigurationManager::instance().setAccountsOrder(order);
}

QString
AccountModel::accountVCard(const QString& accountId, bool compressImage) const
{
    return authority::storage::vcard::profileToVcard(getAccountInfo(accountId).profileInfo,
                                                     compressImage);
}

const QString
AccountModel::bestNameForAccount(const QString& accountID)
{
    // Order: Alias, registeredName, uri
    auto& accountInfo = getAccountInfo(accountID);

    auto alias = accountInfo.profileInfo.alias.simplified();
    auto registeredName = accountInfo.registeredName.simplified();
    auto infoHash = accountInfo.profileInfo.uri.simplified();

    if (alias.isEmpty()) {
        if (registeredName.isEmpty())
            return infoHash;
        else
            return registeredName;
    }
    return alias;
}

const QString
AccountModel::bestIdForAccount(const QString& accountID)
{
    // Order: RegisteredName, uri after best name
    //        return empty string if duplicated with best name
    auto& accountInfo = getAccountInfo(accountID);

    auto registeredName = accountInfo.registeredName.simplified();
    auto infoHash = accountInfo.profileInfo.uri.simplified();

    return registeredName.isEmpty() ? infoHash : registeredName;
}

void
AccountModel::setDefaultModerator(const QString& accountID,
                                  const QString& peerURI,
                                  const bool& state)
{
    ConfigurationManager::instance().setDefaultModerator(accountID, peerURI, state);
}

QStringList
AccountModel::getDefaultModerators(const QString& accountID)
{
    return ConfigurationManager::instance().getDefaultModerators(accountID);
}

void
AccountModel::enableLocalModerators(const QString& accountID, const bool& isModEnabled)
{
    ConfigurationManager::instance().enableLocalModerators(accountID, isModEnabled);
}

bool
AccountModel::isLocalModeratorsEnabled(const QString& accountID)
{
    return ConfigurationManager::instance().isLocalModeratorsEnabled(accountID);
}

void
AccountModel::setAllModerators(const QString& accountID, const bool& allModerators)
{
    ConfigurationManager::instance().setAllModerators(accountID, allModerators);
}

bool
AccountModel::isAllModerators(const QString& accountID)
{
    return ConfigurationManager::instance().isAllModerators(accountID);
}

int
AccountModel::notificationsCount() const
{
    auto total = 0;
    for (const auto& [_id, account] : pimpl_->accounts) {
        total += account.first.conversationModel->notificationsCount();
    }
    return total;
}

void
AccountModel::reloadHistory()
{
    for (const auto& [_id, account] : pimpl_->accounts) {
        account.first.conversationModel->reloadHistory();
    }
}

QString
AccountModel::avatar(const QString& accountId) const
{
    return authority::storage::avatar(accountId);
}

} // namespace lrc

#include "api/moc_accountmodel.cpp"
#include "accountmodel.moc"
