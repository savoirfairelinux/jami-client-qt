/****************************************************************************
 *    Copyright (C) 2017-2024 Savoir-faire Linux Inc.                       *
 *   Author: Nicolas Jäger <nicolas.jager@savoirfairelinux.com>             *
 *   Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>           *
 *   Author: Guillaume Roguez <guillaume.roguez@savoirfairelinux.com>       *
 *   Author: Hugo Lefeuvre <hugo.lefeuvre@savoirfairelinux.com>             *
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

#include "api/contactmodel.h"

#include <QThreadPool>

// LRC
#include "api/account.h"
#include "api/contact.h"
#include "api/conversationmodel.h"
#include "api/accountmodel.h"
#include "api/callmodel.h"
#include "callbackshandler.h"
#include "uri.h"
#include "vcard.h"
#include "typedefs.h"

#include "authority/daemon.h"
#include "authority/storagehelper.h"

// Dbus
#include "dbus/configurationmanager.h"
#include "dbus/presencemanager.h"

#include "account_const.h"

// Std
#include <algorithm>

namespace lrc {

using namespace api;

class ContactModelPimpl : public QObject
{
    Q_OBJECT
public:
    ContactModelPimpl(const ContactModel& linked,
                      Database& db,
                      const CallbacksHandler& callbacksHandler,
                      const BehaviorController& behaviorController);
    ~ContactModelPimpl() = default;

    /**
     * Fills the contacts based on database's conversations
     * @return if the method succeeds
     */
    bool fillWithSIPContacts();

    /**
     * Fills the contacts based on database's conversations
     * @return if the method succeeds
     */
    bool fillWithJamiContacts();

    /**
     * Add a contact::Info to contacts.
     * @note: the contactId must corresponds to a profile in the database.
     * @param contactId
     * @param type
     * @param displayName
     * @param banned whether contact is banned or not
     * @param conversationId linked swarm if one
     */
    void addToContacts(const QString& contactId,
                       const profile::Type& type,
                       const QString& displayName = "",
                       bool banned = false,
                       const QString& conversationId = "");
    /**
     * Helpers for searchContact. Search for a given classic or SIP contact.
     */
    void searchContact(const URI& query);
    void searchSipContact(const URI& query);

    /**
     * Update temporary item to display a given message about a given uri.
     */
    void updateTemporaryMessage(const QString& mes);

    /**
     * Check if equivalent uri exist in contact
     */
    QString sipUriReceivedFilter(const QString& uri);

    /**
     * Update the cached profile info for a contact.
     * Warning: this method assumes the caller has locked the contacts mutex.
     * @param profileInfo
     */
    void updateCachedProfile(profile::Info& profileInfo);

    // Base template function to get a property from the contact
    template<typename Func>
    QString getCachedProfileProperty(const QString& contactUri, Func extractor);

    // Helpers
    const BehaviorController& behaviorController;
    const ContactModel& linked;
    Database& db;
    const CallbacksHandler& callbacksHandler;

    // Containers
    ContactModel::ContactInfoMap contacts;
    ContactModel::ContactInfoMap searchResult;
    QList<QString> bannedContacts;
    QString searchQuery;
    std::mutex contactsMtx_;
    std::mutex bannedContactsMtx_;
    QString searchStatus_ {};
    QMap<QString, QString> nonContactLookup_;

    // Store if a profile is cached for a given URI.
    QSet<QString> cachedProfiles;

public Q_SLOTS:
    /**
     * Listen CallbacksHandler when a presence update occurs
     * @param accountId
     * @param contactUri
     * @param status
     */
    void slotNewBuddySubscription(const QString& accountId, const QString& uri, int status);

    /**
     * Listen CallbacksHandler when a contact is added
     * @param accountId
     * @param contactUri
     * @param confirmed
     */
    void slotContactAdded(const QString& accountId, const QString& contactUri, bool confirmed);

    /**
     * Listen CallbacksHandler when a contact is removed
     * @param accountId
     * @param contactUri
     * @param banned
     */
    void slotContactRemoved(const QString& accountId, const QString& contactUri, bool banned);

    /**
     * Listen CallbacksHandler when a registeredName is found
     * @param accountId account linked
     * @param status (0 = SUCCESS, 1 = Not found, 2 = Network error)
     * @param uri of the contact found
     * @param registeredName of the contact found
     */
    void slotRegisteredNameFound(const QString& accountId,
                                 int status,
                                 const QString& uri,
                                 const QString& registeredName);

    /**
     * Listen from callModel when an new call is available.
     * @param fromId
     * @param callId
     * @param displayName
     * @param isOutgoing
     * @param toUri
     */
    void slotNewCall(const QString& fromId,
                     const QString& callId,
                     const QString& displayname,
                     bool isOutgoing,
                     const QString& toUri);

    /**
     * Listen from callbacksHandler for new account interaction and add pending contact if not present
     * @param accountId
     * @param msgId
     * @param peerId
     * @param payloads
     */
    void slotNewAccountMessage(const QString& accountId,
                               const QString& peerId,
                               const QString& msgId,
                               const MapStringString& payloads);

    /**
     * Listen from callbacksHandler to know when a file transfer interaction is incoming
     * @param fileId Daemon's ID for incoming transfer
     * @param transferInfo DataTransferInfo structure from daemon
     */
    void slotNewAccountTransfer(const QString& fileId, datatransfer::Info info);

    /**
     * Listen from daemon to know when a VCard is received
     * @param accountId
     * @param peer
     * @param vCard
     */
    void slotProfileReceived(const QString& accountId, const QString& peer, const QString& vCard);

    /**
     * Listen from daemon to know when a user search completed
     * @param accountId
     * @param status
     * @param query
     * @param result
     */
    void slotUserSearchEnded(const QString& accountId,
                             int status,
                             const QString& query,
                             const VectorMapStringString& result);
};

using namespace authority;

ContactModel::ContactModel(const account::Info& owner,
                           Database& db,
                           const CallbacksHandler& callbacksHandler,
                           const BehaviorController& behaviorController)
    : owner(owner)
    , pimpl_(std::make_unique<ContactModelPimpl>(*this, db, callbacksHandler, behaviorController))
{}

ContactModel::~ContactModel() {}

const ContactModel::ContactInfoMap&
ContactModel::getAllContacts() const
{
    return pimpl_->contacts;
}

time_t
ContactModel::getAddedTs(const QString& contactUri) const
{
    MapStringString details = ConfigurationManager::instance().getContactDetails(owner.id,
                                                                                 contactUri);
    auto itAdded = details.find("added");
    if (itAdded == details.end())
        return 0;
    return itAdded.value().toUInt();
}

void
ContactModel::addContact(contact::Info contactInfo)
{
    auto& profile = contactInfo.profileInfo;
    // If passed contact is a banned contact, call the daemon to unban it
    auto it = std::find(pimpl_->bannedContacts.begin(), pimpl_->bannedContacts.end(), profile.uri);
    if (it != pimpl_->bannedContacts.end()) {
        LC_DBG << QString("Unban-ing contact %1").arg(profile.uri);
        ConfigurationManager::instance().addContact(owner.id, profile.uri);
        // bannedContacts will be updated in slotContactAdded
        return;
    }

    if ((owner.profileInfo.type != profile.type)
        and (profile.type == profile::Type::JAMI or profile.type == profile::Type::SIP)) {
        LC_DBG << "ContactModel::addContact, types invalid.";
        return;
    }

    MapStringString details = ConfigurationManager::instance()
                                  .getContactDetails(owner.id, contactInfo.profileInfo.uri);

    // if contactInfo is already a contact for the daemon, type should be equals to RING
    // if the user add a temporary item for a SIP account, should be directly transformed
    if ((!details.empty() && details.value("removed") == "0")
        || (profile.type == profile::Type::TEMPORARY
            && owner.profileInfo.type == profile::Type::SIP))
        profile.type = owner.profileInfo.type;

    switch (profile.type) {
    case profile::Type::TEMPORARY: {
        // make a temporary contact available for UI elements, it will be upgraded to
        // its corresponding type after receiving contact added signal
        std::lock_guard<std::mutex> lk(pimpl_->contactsMtx_);
        contactInfo.profileInfo.type = profile::Type::PENDING;
        pimpl_->contacts.insert(contactInfo.profileInfo.uri, contactInfo);
        ConfigurationManager::instance().addContact(owner.id, profile.uri);
        ConfigurationManager::instance()
            .sendTrustRequest(owner.id,
                              profile.uri,
                              owner.accountModel->accountVCard(owner.id).toUtf8());
        return;
    }
    case profile::Type::PENDING:
        return;
    case profile::Type::JAMI:
    case profile::Type::SIP:
        break;
    case profile::Type::INVALID:
    case profile::Type::COUNT__:
    default:
        LC_DBG << "ContactModel::addContact, cannot add contact with invalid type.";
        return;
    }

    storage::createOrUpdateProfile(owner.id, profile);

    {
        std::lock_guard<std::mutex> lk(pimpl_->contactsMtx_);
        auto iter = pimpl_->contacts.find(contactInfo.profileInfo.uri);
        if (iter == pimpl_->contacts.end())
            pimpl_->contacts.insert(contactInfo.profileInfo.uri, contactInfo);
        else {
            // On non-DBus platform, contactInfo.profileInfo.type may be wrong as the contact
            // may be trusted already. We must use Profile::Type from pimpl_->contacts
            // and not from contactInfo so we cannot revert a contact back to PENDING.
            contactInfo.profileInfo.type = iter->profileInfo.type;
            iter->profileInfo = contactInfo.profileInfo;
        }
    }
    Q_EMIT profileUpdated(profile.uri);
    if (profile.type == profile::Type::SIP)
        Q_EMIT contactAdded(profile.uri);
    else {
        PresenceManager::instance().subscribeBuddy(owner.id, profile.uri, true);
        ConfigurationManager::instance().lookupAddress(owner.id, "", profile.uri);
    }
}

void
ContactModel::removeContact(const QString& contactUri, bool banned)
{
    try {
        const auto& contact = getContact(contactUri);
        if (contact.isBanned) {
            LC_WARN << "Contact already banned";
            return;
        }
    } catch (...) {
    }

    bool emitContactRemoved = false;
    {
        std::lock_guard<std::mutex> lk(pimpl_->contactsMtx_);
        if (owner.profileInfo.type == profile::Type::SIP) {
            // Remove contact from db
            pimpl_->contacts.remove(contactUri);
            storage::removeContactConversations(pimpl_->db, contactUri);
            storage::removeProfile(owner.id, contactUri);
            emitContactRemoved = true;
        }
    }
    // hang up calls with the removed contact as peer
    try {
        auto callinfo = owner.callModel->getCallFromURI(contactUri, true);
        owner.callModel->hangUp(callinfo.id);
    } catch (std::out_of_range& e) {
    }
    if (emitContactRemoved) {
        Q_EMIT contactRemoved(contactUri);
    } else {
        // NOTE: this method is asynchronous, the model will be updated
        // in slotContactRemoved
        daemon::removeContact(owner, contactUri, banned);
    }
}

const contact::Info
ContactModel::getContact(const QString& contactUri) const
{
    std::lock_guard<std::mutex> lk(pimpl_->contactsMtx_);
    if (pimpl_->contacts.contains(contactUri)) {
        return pimpl_->contacts.value(contactUri);
    } else if (pimpl_->searchResult.contains(contactUri)) {
        return pimpl_->searchResult.value(contactUri);
    }
    throw std::out_of_range("Contact out of range");
}

void
ContactModel::updateContact(const QString& uri, const MapStringString& infos)
{
    std::unique_lock<std::mutex> lk(pimpl_->contactsMtx_);
    auto it = pimpl_->contacts.find(uri);
    if (it == pimpl_->contacts.end()) {
        return;
    }

    // Write the updated profile to the in-memory cache
    auto& profileInfo = it->profileInfo;
    if (infos.contains("avatar"))
        profileInfo.avatar = storage::vcard::compressedAvatar(infos["avatar"]);
    if (infos.contains("title"))
        profileInfo.alias = infos["title"];

    // Update the profile in the database
    storage::vcard::setProfile(owner.id, profileInfo, true /*isPeer*/, true /*ov*/);

    // We can consider the contact profile as cached
    pimpl_->cachedProfiles.insert(uri);

    // Update observers
    lk.unlock();
    LC_WARN << "ContactModel::updateContact" << uri;
    Q_EMIT profileUpdated(uri);
    Q_EMIT contactUpdated(uri);
}

const QList<QString>&
ContactModel::getBannedContacts() const
{
    return pimpl_->bannedContacts;
}

ContactModel::ContactInfoMap
ContactModel::getSearchResults() const
{
    return pimpl_->searchResult;
}

void
ContactModel::searchContact(const QString& query)
{
    LC_DBG << "query! " << query;
    // always reset temporary contact
    pimpl_->searchResult.clear();

    auto uri = URI(query);
    QString uriId = uri.format(URI::Section::USER_INFO | URI::Section::HOSTNAME
                               | URI::Section::PORT);
    pimpl_->searchQuery = uriId;

    auto uriScheme = uri.schemeType();
    if (static_cast<int>(uriScheme) > 2 && owner.profileInfo.type == profile::Type::SIP) {
        // sip account do not care if schemeType is NONE, or UNRECOGNIZED (enum value > 2)
        uriScheme = URI::SchemeType::SIP;
    } else if (uriScheme == URI::SchemeType::NONE && owner.profileInfo.type == profile::Type::JAMI) {
        uriScheme = URI::SchemeType::RING;
    }

    if ((uriScheme == URI::SchemeType::SIP || uriScheme == URI::SchemeType::SIPS)
        && owner.profileInfo.type == profile::Type::SIP) {
        pimpl_->searchSipContact(uri);
    } else if (uriScheme == URI::SchemeType::RING && owner.profileInfo.type == profile::Type::JAMI) {
        pimpl_->searchContact(uri);
    } else {
        pimpl_->updateTemporaryMessage(tr("Bad URI scheme"));
    }
}

void
ContactModelPimpl::updateTemporaryMessage(const QString& mes)
{
    if (searchStatus_ != mes) {
        searchStatus_ = mes;
        linked.owner.conversationModel->updateSearchStatus(mes);
    }
}

void
ContactModelPimpl::searchContact(const URI& query)
{
    QString uriId = query.format(URI::Section::USER_INFO | URI::Section::HOSTNAME
                                 | URI::Section::PORT);
    if (query.isEmpty()) {
        // This will remove the temporary item
        Q_EMIT linked.contactUpdated(uriId);
        updateTemporaryMessage("");
        return;
    }

    if (query.protocolHint() == URI::ProtocolHint::RING) {
        updateTemporaryMessage("");
        // no lookup, this is a ring infoHash
        for (auto& i : contacts)
            if (i.profileInfo.uri == uriId)
                return;
        auto& temporaryContact = searchResult[uriId];
        temporaryContact.profileInfo.uri = uriId;
        temporaryContact.profileInfo.alias = uriId;
        temporaryContact.profileInfo.type = profile::Type::TEMPORARY;
        Q_EMIT linked.contactUpdated(uriId);
    } else {
        updateTemporaryMessage(tr("Searching…"));

        // If the username contains an @ it's an exact match
        bool isJamsAccount = !linked.owner.confProperties.managerUri.isEmpty();
        if (isJamsAccount and not query.hasHostname())
            ConfigurationManager::instance().searchUser(linked.owner.id, uriId);
        else
            ConfigurationManager::instance().lookupName(linked.owner.id, "", uriId);
    }
}

void
ContactModelPimpl::searchSipContact(const URI& query)
{
    QString uriId = query.format(URI::Section::USER_INFO | URI::Section::HOSTNAME
                                 | URI::Section::PORT);
    if (query.isEmpty()) {
        // This will remove the temporary item
        Q_EMIT linked.contactUpdated(uriId);
        updateTemporaryMessage("");
        return;
    }

    {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        if (contacts.find(uriId) == contacts.end()) {
            auto& temporaryContact = searchResult[query];

            temporaryContact.profileInfo.uri = uriId;
            temporaryContact.profileInfo.alias = uriId;
            temporaryContact.profileInfo.type = profile::Type::TEMPORARY;
        }
    }
    Q_EMIT linked.contactUpdated(uriId);
}

uint64_t
ContactModel::sendDhtMessage(const QString& contactUri,
                             const QString& body,
                             const QString& mimeType,
                             int flag) const
{
    // Send interaction
    QMap<QString, QString> payloads;
    if (mimeType.isEmpty())
        payloads[TEXT_PLAIN] = body;
    else
        payloads[mimeType] = body;
    auto msgId = ConfigurationManager::instance().sendTextMessage(QString(owner.id),
                                                                  QString(contactUri),
                                                                  payloads,
                                                                  flag);
    // NOTE: ConversationModel should store the interaction into the database
    return msgId;
}

const QString
ContactModel::bestNameForContact(const QString& contactUri) const
{
    if (contactUri.isEmpty())
        return contactUri;
    if (contactUri == owner.profileInfo.uri)
        return owner.accountModel->bestNameForAccount(owner.id);
    QString res = contactUri;
    try {
        auto contact = getContact(contactUri);
        auto alias = displayName(contactUri).simplified();
        if (alias.isEmpty()) {
            return bestIdFromContactInfo(contact);
        }
        return alias;
    } catch (const std::out_of_range&) {
        auto itContact = pimpl_->nonContactLookup_.find(contactUri);
        if (itContact != pimpl_->nonContactLookup_.end()) {
            return *itContact;
        } else {
            // This is not a contact, but we should get the registered name
            ConfigurationManager::instance().lookupAddress(owner.id, "", contactUri);
        }
    }
    return res;
}

QString
ContactModel::avatar(const QString& contactUri) const
{
    return pimpl_->getCachedProfileProperty(contactUri, [](const profile::Info& profile) {
        return profile.avatar;
    });
}

QString
ContactModel::displayName(const QString& contactUri) const
{
    return pimpl_->getCachedProfileProperty(contactUri, [](const profile::Info& profile) {
        return profile.alias;
    });
}

const QString
ContactModel::bestIdForContact(const QString& contactUri) const
{
    std::lock_guard<std::mutex> lk(pimpl_->contactsMtx_);
    if (pimpl_->contacts.contains(contactUri)) {
        auto contact = pimpl_->contacts.value(contactUri);
        return bestIdFromContactInfo(contact);
    }
    return contactUri;
}

const QString
ContactModel::bestIdFromContactInfo(const contact::Info& contactInfo) const
{
    auto registeredName = contactInfo.registeredName.simplified();
    auto infoHash = contactInfo.profileInfo.uri.simplified();

    if (!registeredName.isEmpty()) {
        return registeredName;
    }
    return infoHash;
}

ContactModelPimpl::ContactModelPimpl(const ContactModel& linked,
                                     Database& db,
                                     const CallbacksHandler& callbacksHandler,
                                     const BehaviorController& behaviorController)
    : linked(linked)
    , db(db)
    , behaviorController(behaviorController)
    , callbacksHandler(callbacksHandler)
{
    // connect the signals
    connect(&callbacksHandler,
            &CallbacksHandler::newBuddySubscription,
            this,
            &ContactModelPimpl::slotNewBuddySubscription);
    connect(&callbacksHandler,
            &CallbacksHandler::contactAdded,
            this,
            &ContactModelPimpl::slotContactAdded);
    connect(&callbacksHandler,
            &CallbacksHandler::contactRemoved,
            this,
            &ContactModelPimpl::slotContactRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::registeredNameFound,
            this,
            &ContactModelPimpl::slotRegisteredNameFound);
    connect(&*linked.owner.callModel, &CallModel::newCall, this, &ContactModelPimpl::slotNewCall);
    connect(&callbacksHandler,
            &lrc::CallbacksHandler::newAccountMessage,
            this,
            &ContactModelPimpl::slotNewAccountMessage);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusCreated,
            this,
            &ContactModelPimpl::slotNewAccountTransfer);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::profileReceived,
            this,
            &ContactModelPimpl::slotProfileReceived);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::userSearchEnded,
            this,
            &ContactModelPimpl::slotUserSearchEnded);

    if (this->linked.owner.profileInfo.type == profile::Type::SIP)
        fillWithSIPContacts();
    else
        fillWithJamiContacts();
}

bool
ContactModelPimpl::fillWithSIPContacts()
{
    auto conversationsForAccount = storage::getAllConversations(db);
    for (const auto& convId : conversationsForAccount) {
        auto otherParticipants = storage::getPeerParticipantsForConversation(db, convId);
        for (const auto& participant : otherParticipants) {
            // for each conversations get the other profile id
            auto contactInfo = storage::buildContactFromProfile(linked.owner.id,
                                                                participant,
                                                                profile::Type::SIP);
            {
                std::lock_guard<std::mutex> lk(contactsMtx_);
                contacts.insert(contactInfo.profileInfo.uri, contactInfo);
            }
        }
    }

    return true;
}

bool
ContactModelPimpl::fillWithJamiContacts()
{
    // Add existing contacts from libjami
    // Note: explicit type is required here for DBus build
    const VectorMapStringString& contacts_vector = ConfigurationManager::instance().getContacts(
        linked.owner.id);
    for (auto contact_info : contacts_vector)
        addToContacts(contact_info["id"],
                      linked.owner.profileInfo.type,
                      "",
                      contact_info["banned"] == "true",
                      contact_info["conversationId"]);

    // Add pending contacts
    const VectorMapStringString& pending_tr {
        ConfigurationManager::instance().getTrustRequests(linked.owner.id)};
    for (const auto& tr_info : pending_tr) {
        // Get pending requests.
        auto payload = tr_info[libjami::Account::TrustRequest::PAYLOAD].toUtf8();
        auto contactUri = tr_info[libjami::Account::TrustRequest::FROM];
        auto convId = tr_info[libjami::Account::TrustRequest::CONVERSATIONID];
        if (!convId.isEmpty())
            continue; // This will be added via getConversationsRequests

        auto contactInfo = storage::buildContactFromProfile(linked.owner.id,
                                                            contactUri,
                                                            profile::Type::PENDING);

        const auto vCard = lrc::vCard::utils::toHashMap(payload);
        const auto alias = vCard["FN"];
        contactInfo.profileInfo.type = profile::Type::PENDING;
        if (!alias.isEmpty())
            contactInfo.profileInfo.alias = alias.constData();
        contactInfo.registeredName = "";
        contactInfo.isBanned = false;

        {
            std::lock_guard<std::mutex> lk(contactsMtx_);
            contacts.insert(contactUri, contactInfo);
        }

        // create profile vcard for contact
        storage::vcard::setProfile(linked.owner.id, contactInfo.profileInfo, true);
    }

    // Update presence
    // TODO fix this map. This is dumb for now. The map contains values as keys, and empty values.
    const VectorMapStringString& subscriptions {
        PresenceManager::instance().getSubscriptions(linked.owner.id)};
    for (const auto& subscription : subscriptions) {
        auto first = true;
        QString uri = "";
        for (const auto& key : subscription) {
            if (first) {
                first = false;
                uri = key;
            } else {
                {
                    std::lock_guard<std::mutex> lk(contactsMtx_);
                    auto it = contacts.find(uri);
                    if (it != contacts.end()) {
                        it->presence = key == "Online" ? 1 : 0;
                        Q_EMIT linked.contactUpdated(uri);
                    }
                }
                break;
            }
        }
    }
    return true;
}

void
ContactModelPimpl::slotNewBuddySubscription(const QString& accountId,
                                            const QString& contactUri,
                                            int state)
{
    // LC_WARN << "ContactModelPimpl::slotNewBuddySubscription" << accountId << contactUri << state;
    if (accountId != linked.owner.id)
        return;
    {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        auto it = contacts.find(contactUri);
        if (it != contacts.end()) {
            it->presence = state;
        } else
            return;
    }
    Q_EMIT linked.contactUpdated(contactUri);
}

void
ContactModelPimpl::slotContactAdded(const QString& accountId, const QString& contactUri, bool)
{
    if (accountId != linked.owner.id)
        return;
    auto contact = contacts.find(contactUri);
    if (contact != contacts.end()) {
        if (contact->isBanned) {
            // Continue
        } else if (contact->profileInfo.type == profile::Type::PENDING) {
            Q_EMIT behaviorController.trustRequestTreated(linked.owner.id, contactUri);
            // Continue
        } else {
            return;
        }
    }

    // for jams account we already have profile with avatar, use it to save to vCard
    bool isJamsAccount = !linked.owner.confProperties.managerUri.isEmpty();
    if (isJamsAccount) {
        auto result = searchResult.find(contactUri);
        if (result != searchResult.end()) {
            storage::createOrUpdateProfile(linked.owner.id, result->profileInfo);
        }
    }

    bool isBanned = false;
    {
        // Always get contactsMtx_ lock before bannedContactsMtx_.
        std::lock_guard<std::mutex> lk(contactsMtx_);
        {
            // Check whether contact is banned or not
            std::lock_guard<std::mutex> lk(bannedContactsMtx_);
            auto it = std::find(bannedContacts.cbegin(), bannedContacts.cend(), contactUri);

            isBanned = (it != bannedContacts.cend());

            // If contact is banned, do not re-add it, simply update its flag and the banned contacts list
            if (isBanned) {
                bannedContacts.erase(it);
            }
        }
    }

    // Note: explicit type is required here for DBus build
    MapStringString details = ConfigurationManager::instance().getContactDetails(linked.owner.id,
                                                                                 contactUri);
    addToContacts(contactUri, linked.owner.profileInfo.type, "", false, details["conversationId"]);

    if (isBanned) {
        // Update the smartlist
        linked.owner.conversationModel->refreshFilter();
        Q_EMIT linked.bannedStatusChanged(contactUri, false);
    } else {
        Q_EMIT linked.contactAdded(contactUri);
    }
}

void
ContactModelPimpl::slotContactRemoved(const QString& accountId,
                                      const QString& contactUri,
                                      bool banned)
{
    if (accountId != linked.owner.id)
        return;

    {
        // Always get contactsMtx_ lock before bannedContactsMtx_.
        std::lock_guard<std::mutex> lk(contactsMtx_);

        auto contact = contacts.find(contactUri);
        if (contact == contacts.end()) {
            return;
        }

        if (contact->profileInfo.type == profile::Type::PENDING) {
            Q_EMIT behaviorController.trustRequestTreated(linked.owner.id, contactUri);
        }

        if (contact->profileInfo.type != profile::Type::SIP)
            PresenceManager::instance().subscribeBuddy(linked.owner.id, contactUri, false);

        if (banned) {
            contact->isBanned = true;
            // Update bannedContacts index
            bannedContacts.append(contact->profileInfo.uri);
        } else {
            if (contact->isBanned) {
                // Contact was banned, update bannedContacts
                std::lock_guard<std::mutex> lk(bannedContactsMtx_);
                auto it = std::find(bannedContacts.cbegin(),
                                    bannedContacts.cend(),
                                    contact->profileInfo.uri);
                if (it == bannedContacts.cend()) {
                    // should not happen
                    LC_DBG << "Contact is banned but not present in bannedContacts. This is most "
                              "likely the result of an earlier bug.";
                } else {
                    bannedContacts.erase(it);
                }
            }
            storage::removeContactConversations(db, contactUri);
            storage::removeProfile(linked.owner.id, contactUri);
            contacts.remove(contactUri);
        }
    }

    // Update the smartlist
    linked.owner.conversationModel->refreshFilter();
    if (banned) {
        Q_EMIT linked.bannedStatusChanged(contactUri, true);
    } else {
        Q_EMIT linked.contactRemoved(contactUri);
    }
}

void
ContactModelPimpl::addToContacts(const QString& contactUri,
                                 const profile::Type& type,
                                 const QString& displayName,
                                 bool banned,
                                 const QString& conversationId)
{
    // create a vcard if necessary
    profile::Info profileInfo {contactUri, {}, displayName, linked.owner.profileInfo.type};
    api::contact::Info contactInfo = {profileInfo, "", type == api::profile::Type::JAMI, false};

    contactInfo.isBanned = banned;
    contactInfo.conversationId = conversationId;

    if (type == profile::Type::JAMI) {
        ConfigurationManager::instance().lookupAddress(linked.owner.id, "", contactUri);
        PresenceManager::instance().subscribeBuddy(linked.owner.id, contactUri, !banned);
    } else {
        contactInfo.profileInfo.alias = displayName;
    }

    contactInfo.profileInfo.type = type; // Because PENDING should not be stored in the database
    {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        auto iter = contacts.find(contactInfo.profileInfo.uri);
        if (iter != contacts.end()) {
            auto info = iter.value();
            contactInfo.registeredName = info.registeredName;
            contactInfo.presence = info.presence;
            iter.value() = contactInfo;
        } else {
            contacts.insert(contactInfo.profileInfo.uri, contactInfo);
        }
        if (banned) {
            std::lock_guard<std::mutex> lk(bannedContactsMtx_);
            bannedContacts.append(contactUri);
        }
    }
}

void
ContactModelPimpl::slotRegisteredNameFound(const QString& accountId,
                                           int status,
                                           const QString& uri,
                                           const QString& registeredName)
{
    if (accountId != linked.owner.id)
        return;

    if (status == 0 /* SUCCESS */) {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        if (contacts.find(uri) != contacts.end()) {
            // update contact and remove temporary item
            contacts[uri].registeredName = registeredName;
            searchResult.clear();
        } else {
            nonContactLookup_[uri] = registeredName;
            if ((searchQuery != uri && searchQuery != registeredName) || searchQuery.isEmpty()) {
                // we are notified that a previous lookup ended
                return;
            }
            // Update the temporary item
            lrc::api::profile::Info profileInfo = {uri, "", "", profile::Type::TEMPORARY};
            searchResult[uri] = {profileInfo, registeredName, false, false};
        }
    } else {
        {
            std::lock_guard<std::mutex> lk(contactsMtx_);
            if (contacts.find(uri) != contacts.end()) {
                // it was lookup for contact
                return;
            }
        }
        if ((searchQuery != uri && searchQuery != registeredName) || searchQuery.isEmpty()) {
            // we are notified that a previous lookup ended
            return;
        }
        switch (status) {
        case 1 /* INVALID */:
            updateTemporaryMessage(tr("Invalid ID"));
            break;
        case 2 /* NOT FOUND */:
            updateTemporaryMessage(tr("Username not found"));
            break;
        case 3 /* ERROR */:
            updateTemporaryMessage(tr("Couldn't lookup…"));
            break;
        }
        return;
    }
    updateTemporaryMessage("");
    // TODO: be more granular about this update (add a signal for registeredName)?
    Q_EMIT linked.contactUpdated(uri);
}

void
ContactModelPimpl::slotNewCall(const QString& fromId,
                               const QString& callId,
                               const QString& displayname,
                               bool isOutgoing,
                               const QString& toUri)
{
    if (!isOutgoing && toUri == linked.owner.profileInfo.uri) {
        bool addContact = false;
        {
            std::lock_guard<std::mutex> lk(contactsMtx_);
            auto it = contacts.find(fromId);
            if (it == contacts.end()) {
                // Contact not found, load profile from database.
                // The conversation model will create an entry and link the incomingCall.
                addContact = true;
            } else {
                // Update the display name
                if (!displayname.isEmpty()) {
                    it->profileInfo.alias = displayname;
                    storage::vcard::setProfile(linked.owner.id, it->profileInfo, true);
                    cachedProfiles.insert(it->profileInfo.uri);
                }
            }
        }
        if (addContact) {
            auto type = (linked.owner.profileInfo.type == profile::Type::JAMI)
                            ? profile::Type::PENDING
                            : profile::Type::SIP;
            addToContacts(fromId, type, displayname, false);

            if (linked.owner.profileInfo.type == profile::Type::SIP)
                Q_EMIT linked.contactAdded(fromId);
            else if (linked.owner.profileInfo.type == profile::Type::JAMI)
                Q_EMIT behaviorController.newTrustRequest(linked.owner.id, "", fromId);
        } else
            Q_EMIT linked.profileUpdated(fromId);
    }
    Q_EMIT linked.newCall(fromId, callId, isOutgoing, toUri);
}

void
ContactModelPimpl::slotNewAccountMessage(const QString& accountId,
                                         const QString& peerId,
                                         const QString& msgId,
                                         const MapStringString& payloads)
{
    if (accountId != linked.owner.id)
        return;

    QString peerId2(peerId);

    auto addContact = false;
    {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        if (contacts.find(peerId) == contacts.end()) {
            // Contact not found, load profile from database.
            // The conversation model will create an entry and link the incomingCall.
            addContact = true;
        }
    }

    if (addContact) {
        if (linked.owner.profileInfo.type == profile::Type::SIP) {
            QString potentialContact = sipUriReceivedFilter(peerId);
            if (potentialContact.isEmpty()) {
                addToContacts(peerId, profile::Type::SIP, "", false);
            } else {
                // equivalent uri exist, use that uri
                peerId2 = potentialContact;
            }
        } else {
            addToContacts(peerId, profile::Type::PENDING, "", false);
            Q_EMIT behaviorController.newTrustRequest(linked.owner.id, "", peerId);
        }
    }

    Q_EMIT linked.newAccountMessage(accountId, peerId2, msgId, payloads);
}

QString
ContactModelPimpl::sipUriReceivedFilter(const QString& uri)
{
    // this function serves when the uri is not found in the contact list
    // return "" means need to add new contact, else means equivalent uri exist
    std::string uriCopy = uri.toStdString();

    auto pos = uriCopy.find("@");
    auto ownerHostName = linked.owner.confProperties.hostname.toStdString();

    if (pos != std::string::npos) {
        // "@" is found, separate username and hostname
        std::string hostName = uriCopy.substr(pos + 1);
        uriCopy.erase(uriCopy.begin() + pos, uriCopy.end());
        std::string remoteUser = std::move(uriCopy);

        if (hostName.compare(ownerHostName) == 0) {
            auto remoteUserQStr = QString::fromStdString(remoteUser);
            if (contacts.find(remoteUserQStr) != contacts.end()) {
                return remoteUserQStr;
            }
            if (remoteUser.at(0) == '+') {
                // "+" - country dial-in codes
                // maximum 3 digits
                for (int i = 2; i <= 4; i++) {
                    QString tempUserName = QString::fromStdString(remoteUser.substr(i));
                    if (contacts.find(tempUserName) != contacts.end()) {
                        return tempUserName;
                    }
                }
                return "";
            } else {
                // if not "+"  from incoming
                // sub "+" char from contacts to see if user exit
                for (auto it = contacts.cbegin(); it != contacts.cend(); ++it) {
                    const QString& contactUri = it.key();
                    if (!contactUri.isEmpty()) {
                        for (int j = 2; j <= 4; j++) {
                            if (contactUri.mid(j) == remoteUserQStr) {
                                return contactUri;
                            }
                        }
                    }
                }
                return "";
            }
        }
        // different hostname means not a phone number
        // no need to check country dial-in codes
        return "";
    }
    // "@" is not found -> not possible since all response uri has one
    return "";
}

void
ContactModelPimpl::updateCachedProfile(profile::Info& profileInfo)
{
    LC_WARN << "ContactModelPimpl::updateCachedProfile" << profileInfo.uri;

    // WARNING: this method assumes the caller has locked the contacts mutex
    const auto newProfileInfo = storage::getProfileData(linked.owner.id, profileInfo.uri);

    profileInfo.alias = newProfileInfo["alias"];
    profileInfo.avatar = newProfileInfo["avatar"];

    // No matter what has been updated here, we want to make sure the contact
    // is considered cached now.
    cachedProfiles.insert(profileInfo.uri);
}

void
ContactModelPimpl::slotNewAccountTransfer(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;

    auto addContact = false;
    {
        std::lock_guard<std::mutex> lk(contactsMtx_);
        // Note: just add a contact for compatibility (so not for swarm).
        if (info.conversationId.isEmpty() && !info.peerUri.isEmpty()
            && contacts.find(info.peerUri) == contacts.end()) {
            // Contact not found, load profile from database.
            // The conversation model will create an entry and link the incomingCall.
            addContact = true;
        }
    }

    if (addContact) {
        auto type = (linked.owner.profileInfo.type == profile::Type::JAMI) ? profile::Type::PENDING
                                                                           : profile::Type::SIP;
        addToContacts(info.peerUri, type, "", false);
        Q_EMIT behaviorController.newTrustRequest(linked.owner.id, "", info.peerUri);
    }

    Q_EMIT linked.newAccountTransfer(fileId, info);
}

void
ContactModelPimpl::slotProfileReceived(const QString& accountId,
                                       const QString& peer,
                                       const QString& path)
{
    Q_UNUSED(path);

    if (accountId != linked.owner.id)
        return;

    // Make sure this is for a contact and not the linked account,
    // then just remove the URI from the cache list and notify.
    std::lock_guard<std::mutex> lk(contactsMtx_);
    if (contacts.find(peer) != contacts.end()) {
        // Remove the URI from the cache list and notify.
        cachedProfiles.remove(peer);
        // This signal should be listened to in order to update contact display names
        // and avatars in the client.
        Q_EMIT linked.profileUpdated(peer);
    }
}

void
ContactModelPimpl::slotUserSearchEnded(const QString& accountId,
                                       int status,
                                       const QString& query,
                                       const VectorMapStringString& result)
{
    if (searchQuery != query)
        return;
    if (accountId != linked.owner.id)
        return;
    searchResult.clear();
    switch (status) {
    case 0: /* SUCCESS */
        for (auto& resultInfo : result) {
            if (contacts.find(resultInfo.value("id")) != contacts.end()) {
                continue;
            }
            profile::Info profileInfo;
            profileInfo.uri = resultInfo.value("id");
            profileInfo.type = profile::Type::TEMPORARY;
            profileInfo.avatar = resultInfo.value("profilePicture");
            profileInfo.alias = resultInfo.value("firstName") + " " + resultInfo.value("lastName");
            contact::Info contactInfo;
            contactInfo.profileInfo = profileInfo;
            contactInfo.registeredName = resultInfo.value("username");
            searchResult.insert(profileInfo.uri, contactInfo);
        }
        updateTemporaryMessage("");
        break;
    case 3: /* ERROR */
        updateTemporaryMessage("could not find contact matching search");
        break;
    default:
        break;
    }
    Q_EMIT linked.contactUpdated(query);
}

template<typename Func>
QString
ContactModelPimpl::getCachedProfileProperty(const QString& contactUri, Func extractor)
{
    std::lock_guard<std::mutex> lk(contactsMtx_);
    // For search results it's loaded and not in storage yet.
    if (searchResult.contains(contactUri)) {
        auto contact = searchResult.value(contactUri);
        return extractor(contact.profileInfo);
    }

    // Try to find the contact.
    auto it = contacts.find(contactUri);
    if (it == contacts.end()) {
        return {};
    }

    // If we have a profile that appears to be recently cached, return the extracted property.
    if (cachedProfiles.contains(contactUri)) {
        return extractor(it->profileInfo);
    }

    // Otherwise, update the profile info and return the extracted property.
    updateCachedProfile(it->profileInfo);

    return extractor(it->profileInfo);
}

} // namespace lrc

#include "api/moc_contactmodel.cpp"
#include "contactmodel.moc"
