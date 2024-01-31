/****************************************************************************
 *    Copyright (C) 2017-2024 Savoir-faire Linux Inc.                       *
 *   Author: Nicolas Jäger <nicolas.jager@savoirfairelinux.com>             *
 *   Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>           *
 *   Author: Guillaume Roguez <guillaume.roguez@savoirfairelinux.com>       *
 *   Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>       *
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
#include "api/conversationmodel.h"

// LRC
#include "api/lrc.h"
#include "api/behaviorcontroller.h"
#include "api/contactmodel.h"
#include "api/callmodel.h"
#include "api/accountmodel.h"
#include "api/account.h"
#include "api/call.h"
#include "api/datatransfer.h"
#include "api/datatransfermodel.h"
#include "callbackshandler.h"
#include "containerview.h"
#include "authority/storagehelper.h"
#include "uri.h"

// Dbus
#include "dbus/configurationmanager.h"
#include "dbus/callmanager.h"

// daemon
#include <account_const.h>
#include <datatransfer_interface.h>

// Qt
#include <QtCore/QTimer>
#include <QFileInfo>

// std
#include <algorithm>
#include <mutex>
#include <regex>
#include <sstream>

namespace lrc {

using namespace authority;
using namespace api;

class ConversationModelPimpl : public QObject
{
    Q_OBJECT
public:
    ConversationModelPimpl(const ConversationModel& linked,
                           Lrc& lrc,
                           Database& db,
                           const CallbacksHandler& callbacksHandler,
                           const BehaviorController& behaviorController);

    ~ConversationModelPimpl();

    using FilterPredicate = std::function<bool(const conversation::Info& convInfo)>;

    /**
     * return a conversation index from conversations or -1 if no index is found.
     * @param uid of the contact to search.
     * @return an int.
     */
    int indexOf(const QString& uid) const;

    /**
     * return a reference to a conversation with given filter
     * @param pred a unary comparison predicate with which to find the conversation
     * @param searchResultIncluded if need to search in contacts and userSearch
     * @return a reference to a conversation with given uid
     */
    std::reference_wrapper<conversation::Info> getConversation(
        const FilterPredicate& pred, const bool searchResultIncluded = false) const;

    /**
     * return a reference to a conversation with given uid.
     * @param conversation uid.
     * @param searchResultIncluded if need to search in contacts and userSearch.
     * @return a reference to a conversation with the given uid.
     */
    std::reference_wrapper<conversation::Info> getConversationForUid(
        const QString& uid, const bool searchResultIncluded = false) const;

    /**
     * return a reference to a conversation with participant.
     * @param participant uri.
     * @param searchResultIncluded if need to search in contacts and userSearch.
     * @return a reference to a conversation with the given peer uri.
     * @warning we could  have multiple swarm conversations for the same peer. This function will
     * return an active one-to-one conversation.
     */
    std::reference_wrapper<conversation::Info> getConversationForPeerUri(
        const QString& uri, const bool searchResultIncluded = false) const;
    /**
     * return a vector of conversation indices for the given contact uri empty
     * if no index is found
     * @param uri of the contact to search
     * @return an vector of indices
     */
    std::vector<int> getIndicesForContact(const QString& uri) const;
    /**
     * Initialize conversations_ and filteredConversations_
     */
    void initConversations();
    /**
     * Filter all conversations
     */
    bool filter(const conversation::Info& conv);
    /**
     * Sort conversation by last action
     */
    bool sort(const conversation::Info& convA, const conversation::Info& convB);
    /**
     * Call contactModel.addContact if necessary
     * @param contactUri
     */
    void sendContactRequest(const QString& contactUri);
    /**
     * Add a conversation with contactUri
     * @param convId
     * @param contactUri
     */
    void addConversationWith(const QString& convId, const QString& contactUri, bool isRequest);
    /**
     * Add a swarm conversation to conversation list
     * @param convId
     */
    void addSwarmConversation(const QString& convId);
    /**
     * Add call interaction for conversation with callId
     * @param callId
     * @param duration
     */
    void addOrUpdateCallMessage(const QString& callId,
                                const QString& from,
                                bool incoming,
                                const std::time_t& duration = -1);
    /**
     * Add a new message from a peer in the database
     * @param peerId          the author id
     * @param body          the content of the message
     * @param timestamp     the timestamp of the message
     * @param daemonId      the daemon id
     * @return msgId generated (in db)
     */
    QString addIncomingMessage(const QString& peerId,
                               const QString& body,
                               const uint64_t& timestamp = 0,
                               const QString& daemonId = "");
    /**
     * Change the status of an interaction. Listen from callbacksHandler
     * @param accountId, account linked
     * @param messageId, interaction to update
     * @param conversationId, conversation
     * @param peerId, peer id
     * @param status, new status for this interaction
     */
    void updateInteractionStatus(const QString& accountId,
                                 const QString& conversationId,
                                 const QString& peerId,
                                 const QString& messageId,
                                 int status);

    /**
     * place a call
     * @param uid, conversation id
     * @param isAudioOnly, allow to specify if the call is only audio. Set to false by default.
     */
    void placeCall(const QString& uid, bool isAudioOnly = false);

    /**
     * get number of unread messages
     */
    int getNumberOfUnreadMessagesFor(const QString& uid);

    /**
     * Handle data transfer progression
     */
    void updateTransferProgress(QTimer* timer, int conversationIdx, const QString& interactionId);

    bool usefulDataFromDataTransfer(const QString& fileId,
                                    const datatransfer::Info& info,
                                    QString& interactionId,
                                    QString& conversationId);
    void awaitingHost(const QString& fileId, datatransfer::Info info);

    bool hasOneOneSwarmWith(const QString& participant);

    /**
     * accept a file transfer
     * @param convUid
     * @param interactionId
     */
    void acceptTransfer(const QString& convUid, const QString& interactionId);
    void handleIncomingFile(const QString& convId, const QString& interactionId, int totalSize);
    void addConversationRequest(const MapStringString& convRequest, bool emitToClient = false);
    void addContactRequest(const QString& contactUri);

    // filter out ourself from conversation participants.
    const VectorString peersForConversation(const conversation::Info& conversation) const;
    void invalidateModel();
    void emplaceBackConversation(conversation::Info&& conversation);
    void eraseConversation(const QString& convId);
    void eraseConversation(int index);

    const ConversationModel& linked;
    Lrc& lrc;
    Database& db;
    const CallbacksHandler& callbacksHandler;
    const BehaviorController& behaviorController;

    ConversationModel::ConversationQueue conversations; ///< non-filtered conversations
    ConversationModel::ConversationQueue searchResults;

    ConversationModel::ConversationQueueProxy filteredConversations;
    ConversationModel::ConversationQueueProxy customFilteredConversations;

    QString currentFilter;
    FilterType typeFilter;
    FilterType customTypeFilter;

    MapStringString transfIdToDbIntId;
    uint32_t mediaResearchRequestId;
    uint32_t msgResearchRequestId;

public Q_SLOTS:
    /**
     * Listen from contactModel when updated (like new alias, avatar, etc.)
     */
    void slotContactModelUpdated(const QString& uri);
    /**
     * Listen from contactModel when a new contact is added
     * @param uri
     */
    void slotContactAdded(const QString& contactUri);
    /**
     * Listen from contactModel when a pending contact is accepted
     * @param uri
     */
    void slotPendingContactAccepted(const QString& uri);
    /**
     * Listen from contactModel when aa new contact is removed
     * @param uri
     */
    void slotContactRemoved(const QString& uri);
    /**
     * Listen from callmodel for new calls.
     * @param fromId caller uri
     * @param callId
     * @param isOutgoing
     * @param toUri
     */
    void slotNewCall(const QString& fromId,
                     const QString& callId,
                     bool isOutgoing,
                     const QString& toUri);
    /**
     * Listen from callmodel for calls status changed.
     * @param callId
     */
    void slotCallStatusChanged(const QString& callId, int code);
    /**
     * Listen from callmodel for writing "Call started"
     * @param callId
     */
    void slotCallStarted(const QString& callId);
    /**
     * Listen from callmodel for writing "Call ended"
     * @param callId
     */
    void slotCallEnded(const QString& callId);
    /**
     * Listen from CallbacksHandler for new incoming interactions;
     * @param accountId
     * @param msgId
     * @param peerId
     * @param payloads body
     */
    void slotNewAccountMessage(const QString& accountId,
                               const QString& peerId,
                               const QString& msgId,
                               const MapStringString& payloads);
    /**
     * Listen from CallbacksHandler for new messages in a SIP call
     * @param accountId account linked to the interaction
     * @param callId call linked to the interaction
     * @param from author uri
     * @param body of the message
     */
    void slotIncomingCallMessage(const QString& accountId,
                                 const QString& callId,
                                 const QString& from,
                                 const QString& body);
    /**
     * Listen from CallModel when a call is added to a conference
     * @param callId
     * @param confId
     */
    void slotCallAddedToConference(const QString& callId, const QString& confId);
    /**
     * Listen from CallbacksHandler when a conference is deleted.
     * @param accountId
     * @param confId
     */
    void slotConferenceRemoved(const QString& accountId, const QString& confId);
    /**
     * Listen for when a contact is composing
     * @param accountId
     * @param contactUri
     * @param isComposing
     */
    void slotComposingStatusChanged(const QString& accountId,
                                    const QString& convId,
                                    const QString& contactUri,
                                    bool isComposing);

    void slotTransferStatusCreated(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusCanceled(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusAwaitingPeer(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusAwaitingHost(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusOngoing(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusFinished(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusError(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusTimeoutExpired(const QString& fileId, api::datatransfer::Info info);
    void slotTransferStatusUnjoinable(const QString& fileId, api::datatransfer::Info info);
    bool updateTransferStatus(const QString& fileId,
                              datatransfer::Info info,
                              interaction::Status newStatus,
                              bool& updated);
    void slotSwarmLoaded(uint32_t requestId,
                         const QString& accountId,
                         const QString& conversationId,
                         const VectorSwarmMessage& messages);
    /**
     * Listen messageFound signal.
     * Is the search response from MessagesAdapter::getConvMedias()
     * @param requestId token of the request
     * @param accountId
     * @param conversationId
     * @param messages Id of all the messages
     */
    void slotMessagesFound(uint32_t requestId,
                           const QString& accountId,
                           const QString& conversationId,
                           const VectorMapStringString& messages);
    void slotMessageReceived(const QString& accountId,
                             const QString& conversationId,
                             const SwarmMessage& message);
    void slotMessageUpdated(const QString& accountId,
                            const QString& conversationId,
                            const SwarmMessage& message);
    void slotReactionAdded(const QString& accountId,
                           const QString& conversationId,
                           const QString& messageId,
                           const MapStringString& reaction);
    void slotReactionRemoved(const QString& accountId,
                             const QString& conversationId,
                             const QString& messageId,
                             const QString& reactionId);
    void slotConversationProfileUpdated(const QString& accountId,
                                        const QString& conversationId,
                                        const MapStringString& profile);
    void slotConversationRequestReceived(const QString& accountId,
                                         const QString& conversationId,
                                         const MapStringString& metadatas);
    void slotConversationMemberEvent(const QString& accountId,
                                     const QString& conversationId,
                                     const QString& memberUri,
                                     int event);
    void slotOnConversationError(const QString& accountId,
                                 const QString& conversationId,
                                 int code,
                                 const QString& what);
    void slotActiveCallsChanged(const QString& accountId,
                                const QString& conversationId,
                                const VectorMapStringString& activeCalls);
    void slotConversationReady(const QString& accountId, const QString& conversationId);
    void slotConversationRemoved(const QString& accountId, const QString& conversationId);
    void slotConversationPreferencesUpdated(const QString& accountId,
                                            const QString& conversationId,
                                            const MapStringString& preferences);
};

ConversationModel::ConversationModel(const account::Info& owner,
                                     Lrc& lrc,
                                     Database& db,
                                     const CallbacksHandler& callbacksHandler,
                                     const BehaviorController& behaviorController)
    : QObject(nullptr)
    , pimpl_(std::make_unique<ConversationModelPimpl>(*this,
                                                      lrc,
                                                      db,
                                                      callbacksHandler,
                                                      behaviorController))
    , owner(owner)
{}

void
ConversationModel::initConversations()
{
    pimpl_->initConversations();
}

ConversationModel::~ConversationModel() {}

const ConversationModel::ConversationQueue&
ConversationModel::getConversations() const
{
    return pimpl_->conversations;
}

const ConversationModel::ConversationQueueProxy&
ConversationModel::allFilteredConversations() const
{
    if (!pimpl_->filteredConversations.isDirty())
        return pimpl_->filteredConversations;

    return pimpl_->filteredConversations.filter().sort().validate();
}

QMap<ConferenceableItem, ConferenceableValue>
ConversationModel::getConferenceableConversations(const QString& convId, const QString& filter) const
{
    auto conversationIdx = pimpl_->indexOf(convId);
    if (conversationIdx == -1 || !owner.enabled) {
        return {};
    }
    QMap<ConferenceableItem, ConferenceableValue> result;
    ConferenceableValue callsVector, contactsVector;

    auto currentConfId = pimpl_->conversations.at(conversationIdx).confId;
    auto currentCallId = pimpl_->conversations.at(conversationIdx).callId;
    auto calls = pimpl_->lrc.getCalls();
    auto conferences = pimpl_->lrc.getConferences(owner.id);
    auto& conversations = pimpl_->conversations;
    auto currentAccountID = pimpl_->linked.owner.id;
    // add contacts for current account
    for (const auto& conv : conversations) {
        // conversations with calls will be added in call section
        // we want to add only contacts non-swarm or one-to-one conversation
        auto& peers = pimpl_->peersForConversation(conv);
        if (!conv.callId.isEmpty() || !conv.confId.isEmpty() || !conv.isCoreDialog()
            || peers.empty()) {
            continue;
        }
        try {
            auto contact = owner.contactModel->getContact(peers.front());
            if (contact.isBanned || contact.profileInfo.type == profile::Type::PENDING) {
                continue;
            }
            QVector<AccountConversation> cv;
            AccountConversation accConv = {conv.uid, currentAccountID};
            cv.push_back(accConv);
            if (filter.isEmpty()) {
                contactsVector.push_back(cv);
                continue;
            }
            bool result = contact.profileInfo.alias.contains(filter, Qt::CaseInsensitive)
                          || contact.profileInfo.uri.contains(filter, Qt::CaseInsensitive)
                          || contact.registeredName.contains(filter, Qt::CaseInsensitive);
            if (result) {
                contactsVector.push_back(cv);
            }
        } catch (const std::out_of_range& e) {
            qDebug() << e.what();
            continue;
        }
    }

    if (calls.empty() && conferences.empty()) {
        result.insert(ConferenceableItem::CONTACT, contactsVector);
        return result;
    }

    // filter out calls from conference
    for (const auto& c : conferences) {
        for (const auto& subcall : owner.callModel->getConferenceSubcalls(c)) {
            const auto position = std::find(calls.cbegin(), calls.cend(), subcall);
            if (position != calls.cend()) {
                calls.erase(position);
            }
        }
    }

    // found conversations and account for calls and conferences
    QMap<QString, QVector<AccountConversation>> tempConferences;
    for (const auto& account_id : pimpl_->lrc.getAccountModel().getAccountList()) {
        try {
            auto& accountInfo = pimpl_->lrc.getAccountModel().getAccountInfo(account_id);
            auto type = accountInfo.profileInfo.type == profile::Type::SIP ? FilterType::SIP
                                                                           : FilterType::JAMI;
            auto accountConv = accountInfo.conversationModel->getFilteredConversations(type);
            accountConv.for_each([this,
                                  filter,
                                  &accountInfo,
                                  account_id,
                                  currentCallId,
                                  currentConfId,
                                  &conferences,
                                  &calls,
                                  &tempConferences,
                                  &callsVector](const conversation::Info& conv) {
                bool confFilterPredicate = !conv.confId.isEmpty() && conv.confId != currentConfId
                                           && std::find(conferences.begin(),
                                                        conferences.end(),
                                                        conv.confId)
                                                  != conferences.end();
                bool callFilterPredicate = !conv.callId.isEmpty() && conv.callId != currentCallId
                                           && std::find(calls.begin(), calls.end(), conv.callId)
                                                  != calls.end();
                auto& peers = pimpl_->peersForConversation(conv);
                if ((!confFilterPredicate && !callFilterPredicate) || !conv.isCoreDialog()) {
                    return;
                }

                // vector of conversationID accountID pair
                // for call has only one entry, for conference multyple
                QVector<AccountConversation> cv;
                AccountConversation accConv = {conv.uid, account_id};
                cv.push_back(accConv);

                bool isConference = !conv.confId.isEmpty();
                // call could be added if it is not conference and in active state
                bool shouldAddCall = false;
                if (!isConference && accountInfo.callModel->hasCall(conv.callId)) {
                    const auto& call = accountInfo.callModel->getCall(conv.callId);
                    shouldAddCall = call.status == lrc::api::call::Status::PAUSED
                                    || call.status == lrc::api::call::Status::IN_PROGRESS;
                }

                auto contact = accountInfo.contactModel->getContact(peers.front());
                // check if contact satisfy filter
                bool result = (filter.isEmpty() || isConference)
                                  ? true
                                  : (contact.profileInfo.alias.contains(filter)
                                     || contact.profileInfo.uri.contains(filter)
                                     || contact.registeredName.contains(filter));
                if (!result) {
                    return;
                }
                if (isConference && tempConferences.count(conv.confId)) {
                    tempConferences.find(conv.confId).value().push_back(accConv);
                } else if (isConference) {
                    tempConferences.insert(conv.confId, cv);
                } else if (shouldAddCall) {
                    callsVector.push_back(cv);
                }
            });
        } catch (...) {
        }
    }
    for (const auto& it : tempConferences.toStdMap()) {
        if (filter.isEmpty()) {
            callsVector.push_back(it.second);
            continue;
        }
        for (const AccountConversation& accConv : it.second) {
            try {
                auto& account = pimpl_->lrc.getAccountModel().getAccountInfo(accConv.accountId);
                auto& conv = account.conversationModel->getConversationForUid(accConv.convId)->get();
                auto& peers = pimpl_->peersForConversation(conv);
                if (!conv.isCoreDialog()) {
                    continue;
                }
                auto cont = account.contactModel->getContact(peers.front());
                if (cont.profileInfo.alias.contains(filter) || cont.profileInfo.uri.contains(filter)
                    || cont.registeredName.contains(filter)) {
                    callsVector.push_back(it.second);
                    continue;
                }
            } catch (...) {
            }
        }
    }
    result.insert(ConferenceableItem::CALL, callsVector);
    result.insert(ConferenceableItem::CONTACT, contactsVector);
    return result;
}

const ConversationModel::ConversationQueue&
ConversationModel::getAllSearchResults() const
{
    return pimpl_->searchResults;
}

const ConversationModel::ConversationQueueProxy&
ConversationModel::getFilteredConversations(const FilterType& filter,
                                            bool forceUpdate,
                                            const bool includeBanned) const
{
    if (pimpl_->customTypeFilter == filter && !pimpl_->customFilteredConversations.isDirty()
        && !forceUpdate)
        return pimpl_->customFilteredConversations;

    pimpl_->customTypeFilter = filter;
    return pimpl_->customFilteredConversations.reset(pimpl_->conversations)
        .filter([this, &includeBanned](const conversation::Info& entry) {
            try {
                if (entry.isLegacy()) {
                    auto& peers = pimpl_->peersForConversation(entry);
                    if (peers.isEmpty()) {
                        return false;
                    }
                    auto contactInfo = owner.contactModel->getContact(peers.front());
                    // do not check blocked contacts for conversation with many participants
                    if (!includeBanned && (contactInfo.isBanned && peers.size() == 1))
                        return false;
                }
                switch (pimpl_->customTypeFilter) {
                case FilterType::JAMI:
                    // we have conversation with many participants only for JAMI
                    return (owner.profileInfo.type == profile::Type::JAMI && !entry.isRequest);
                case FilterType::SIP:
                    return (owner.profileInfo.type == profile::Type::SIP && !entry.isRequest);
                case FilterType::REQUEST:
                    return entry.isRequest;
                case FilterType::INVALID:
                default:
                    break;
                }
            } catch (...) {
            }
            return false;
        })
        .validate();
}

const ConversationModel::ConversationQueueProxy&
ConversationModel::getFilteredConversations(const profile::Type& profileType,
                                            bool forceUpdate,
                                            const bool includeBanned) const
{
    FilterType filterType = FilterType::INVALID;
    switch (profileType) {
    case lrc::api::profile::Type::JAMI:
        filterType = lrc::api::FilterType::JAMI;
        break;
    case lrc::api::profile::Type::SIP:
        filterType = lrc::api::FilterType::SIP;
        break;
    default:
        break;
    }

    return getFilteredConversations(filterType, forceUpdate, includeBanned);
}

OptRef<conversation::Info>
ConversationModel::getConversationForUid(const QString& uid) const
{
    if (!pimpl_) {
        qWarning() << "Invalid pimpl_";
        return std::nullopt;
    }
    try {
        return std::make_optional(pimpl_->getConversationForUid(uid, true));
    } catch (const std::out_of_range&) {
        return std::nullopt;
    }
}

OptRef<conversation::Info>
ConversationModel::getConversationForPeerUri(const QString& uri) const
{
    try {
        return std::make_optional(pimpl_->getConversation(
            [this, uri](const conversation::Info& conv) -> bool {
                if (!conv.isCoreDialog()) {
                    return false;
                }
                if (conv.mode == conversation::Mode::ONE_TO_ONE) {
                    return pimpl_->peersForConversation(conv).indexOf(uri) != -1;
                }
                return uri == pimpl_->peersForConversation(conv).front();
            },
            true));
    } catch (const std::out_of_range&) {
        return std::nullopt;
    }
}

OptRef<conversation::Info>
ConversationModel::getConversationForCallId(const QString& callId) const
{
    try {
        return std::make_optional(pimpl_->getConversation(
            [callId](const conversation::Info& conv) -> bool {
                return (callId == conv.callId || callId == conv.confId);
            },
            true));
    } catch (const std::out_of_range&) {
        return std::nullopt;
    }
}

OptRef<conversation::Info>
ConversationModel::filteredConversation(unsigned row) const
{
    auto conversations = allFilteredConversations();
    if (row >= conversations.get().size())
        return std::nullopt;

    return std::make_optional(conversations.get().at(row));
}

OptRef<conversation::Info>
ConversationModel::searchResultForRow(unsigned row) const
{
    auto& results = pimpl_->searchResults;
    if (row >= results.size())
        return std::nullopt;

    return std::make_optional(std::ref(results.at(row)));
}

void
ConversationModel::makePermanent(const QString& uid)
{
    try {
        auto& conversation = pimpl_->getConversationForUid(uid, true).get();

        if (conversation.participants.empty()) {
            // Should not
            qDebug() << "ConversationModel::addConversation can't add a conversation with no "
                        "participant";
            return;
        }

        // Send contact request if non used
        auto& peers = pimpl_->peersForConversation(conversation);
        if (peers.size() != 1) {
            return;
        }
        pimpl_->sendContactRequest(peers.front());
    } catch (const std::out_of_range& e) {
        qDebug() << "make permanent failed. conversation not found";
    }
}

void
ConversationModel::selectConversation(const QString& uid) const
{
    try {
        auto& conversation = pimpl_->getConversationForUid(uid, true).get();

        bool callEnded = true;
        if (!conversation.callId.isEmpty()) {
            try {
                auto call = owner.callModel->getCall(conversation.callId);
                callEnded = call.status == call::Status::ENDED;
            } catch (...) {
            }
        }
        if (!conversation.confId.isEmpty() && owner.confProperties.isRendezVous) {
            // If we are on a rendez vous account and we select the conversation,
            // attach to the call.
            CallManager::instance().unholdConference(owner.id, conversation.confId);
        }

        if (not callEnded and not conversation.confId.isEmpty()) {
            Q_EMIT pimpl_->behaviorController.showCallView(owner.id, conversation.uid);
        } else if (callEnded) {
            Q_EMIT pimpl_->behaviorController.showChatView(owner.id, conversation.uid);
        } else {
            try {
                auto call = owner.callModel->getCall(conversation.callId);
                switch (call.status) {
                case call::Status::INCOMING_RINGING:
                case call::Status::OUTGOING_RINGING:
                case call::Status::CONNECTING:
                case call::Status::SEARCHING:
                    // We are currently in a call
                    Q_EMIT pimpl_->behaviorController.showIncomingCallView(owner.id,
                                                                           conversation.uid);
                    break;
                case call::Status::PAUSED:
                case call::Status::CONNECTED:
                case call::Status::IN_PROGRESS:
                    // We are currently receiving a call
                    Q_EMIT pimpl_->behaviorController.showCallView(owner.id, conversation.uid);
                    break;
                case call::Status::PEER_BUSY:
                    Q_EMIT pimpl_->behaviorController.showLeaveMessageView(owner.id,
                                                                           conversation.uid);
                    break;
                case call::Status::TIMEOUT:
                case call::Status::TERMINATING:
                case call::Status::INVALID:
                case call::Status::INACTIVE:
                    // call just ended
                    Q_EMIT pimpl_->behaviorController.showChatView(owner.id, conversation.uid);
                    break;
                case call::Status::ENDED:
                default: // ENDED
                    // nothing to do
                    break;
                }
            } catch (const std::out_of_range&) {
                // Should not happen
                Q_EMIT pimpl_->behaviorController.showChatView(owner.id, conversation.uid);
            }
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "select conversation failed. conversation not exists";
    }
}

void
ConversationModel::removeConversation(const QString& uid, bool banned)
{
    // Get conversation
    auto conversationIdx = pimpl_->indexOf(uid);
    if (conversationIdx == -1)
        return;

    auto& conversation = pimpl_->conversations.at(conversationIdx);
    // Remove contact from daemon
    // NOTE: this will also remove the conversation into the database for non-swarm and remove
    // conversation repository for one-to-one.
    auto& peers = pimpl_->peersForConversation(conversation);
    if (peers.empty()) {
        // Should not
        qDebug() << "ConversationModel::removeConversation can't remove a conversation without "
                    "participant";
        return;
    }
    if (conversation.isSwarm() && !banned && !conversation.isCoreDialog()) {
        if (conversation.isRequest) {
            ConfigurationManager::instance().declineConversationRequest(owner.id, uid);
        } else {
            ConfigurationManager::instance().removeConversation(owner.id, uid);
        }
    } else {
        try {
            auto& contact = owner.contactModel->getContact(peers.front());
            owner.contactModel->removeContact(peers.front(), banned);
        } catch (const std::out_of_range&) {
            qWarning() << "Contact not found: " << peers.front();
            ConfigurationManager::instance().removeConversation(owner.id, uid);
        }
    }
}

void
ConversationModel::deleteObsoleteHistory(int days)
{
    if (days < 1)
        return; // unlimited history

    auto currentTime = static_cast<long int>(std::time(nullptr)); // since epoch, in seconds...
    auto date = currentTime - (days * 86400);

    storage::deleteObsoleteHistory(pimpl_->db, date);
}

void
ConversationModel::joinCall(const QString& uid,
                            const QString& uri,
                            const QString& deviceId,
                            const QString& confId,
                            bool isAudioOnly)
{
    try {
        auto& conversation = pimpl_->getConversationForUid(uid, true).get();
        if (!conversation.callId.isEmpty()) {
            qWarning() << "Already in a call for swarm:" + uid;
            return;
        }
        conversation.callId = owner.callModel->createCall("rdv:" + uid + "/" + uri + "/" + deviceId
                                                              + "/" + confId,
                                                          isAudioOnly);
        // Update interaction status
        pimpl_->invalidateModel();
        selectConversation(uid);
        Q_EMIT conversationUpdated(uid);
    } catch (...) {
    }
}

void
ConversationModelPimpl::placeCall(const QString& uid, bool isAudioOnly)
{
    try {
        auto& conversation = getConversationForUid(uid, true).get();
        if (conversation.participants.empty()) {
            // Should not
            qDebug()
                << "ConversationModel::placeCall can't call a conversation without participant";
            return;
        }

        if (!conversation.isCoreDialog() && conversation.isSwarm()) {
            qDebug() << "Start call for swarm:" + uid;
            conversation.callId = linked.owner.callModel->createCall("swarm:" + uid, isAudioOnly);

            // Update interaction status
            invalidateModel();
            linked.selectConversation(conversation.uid);
            Q_EMIT linked.conversationUpdated(conversation.uid);
            Q_EMIT linked.dataChanged(indexOf(conversation.uid));
            return;
        }

        auto& peers = peersForConversation(conversation);
        // there is no calls in group with more than 2 participants
        if (peers.size() != 1) {
            return;
        }
        // Disallow multiple call
        if (!conversation.callId.isEmpty()) {
            try {
                auto call = linked.owner.callModel->getCall(conversation.callId);
                switch (call.status) {
                case call::Status::INCOMING_RINGING:
                case call::Status::OUTGOING_RINGING:
                case call::Status::CONNECTING:
                case call::Status::SEARCHING:
                case call::Status::PAUSED:
                case call::Status::IN_PROGRESS:
                case call::Status::CONNECTED:
                    return;
                case call::Status::INVALID:
                case call::Status::INACTIVE:
                case call::Status::ENDED:
                case call::Status::PEER_BUSY:
                case call::Status::TIMEOUT:
                case call::Status::TERMINATING:
                default:
                    break;
                }
            } catch (const std::out_of_range&) {
            }
        }

        auto convId = uid;

        auto participant = peers.front();
        bool isTemporary = convId == participant || convId == "SEARCHSIP";
        auto contactInfo = linked.owner.contactModel->getContact(participant);
        auto uri = contactInfo.profileInfo.uri;

        if (uri.isEmpty())
            return; // Incorrect item

        // Don't call banned contact
        if (contactInfo.isBanned) {
            qDebug() << "ContactModel::placeCall: denied, contact is banned";
            return;
        }

        if (linked.owner.profileInfo.type != profile::Type::SIP) {
            uri = "ring:" + uri; // Add the ring: before or it will fail.
        }

        auto cb = ([this, isTemporary, uri, isAudioOnly, &conversation](QString conversationId) {
            if (indexOf(conversationId) < 0) {
                qDebug() << "Can't place call: conversation  not exists";
                return;
            }

            auto& newConv = isTemporary ? getConversationForUid(conversationId).get()
                                        : conversation;

            newConv.callId = linked.owner.callModel->createCall(uri, isAudioOnly);
            if (newConv.callId.isEmpty()) {
                qDebug() << "Can't place call (daemon side failure ?)";
                return;
            }

            invalidateModel();

            Q_EMIT behaviorController.showIncomingCallView(linked.owner.id, newConv.uid);
        });

        if (isTemporary) {
            QMetaObject::Connection* const connection = new QMetaObject::Connection;
            *connection = connect(&this->linked,
                                  &ConversationModel::conversationReady,
                                  [cb, connection, convId](QString conversationId,
                                                           QString participantId) {
                                      if (participantId != convId && convId != "SEARCHSIP") {
                                          return;
                                      }
                                      cb(conversationId);
                                      QObject::disconnect(*connection);
                                      if (connection) {
                                          delete connection;
                                      }
                                  });
        }

        sendContactRequest(participant);

        if (!isTemporary) {
            cb(convId);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "could not place call to not existing conversation";
    }
}

void
ConversationModel::placeAudioOnlyCall(const QString& uid)
{
    pimpl_->placeCall(uid, true);
}

void
ConversationModel::placeCall(const QString& uid)
{
    pimpl_->placeCall(uid);
}

MapStringString
ConversationModel::getConversationInfos(const QString& conversationId)
{
    MapStringString ret = ConfigurationManager::instance().conversationInfos(owner.id,
                                                                             conversationId);
    return ret;
}

MapStringString
ConversationModel::getConversationPreferences(const QString& conversationId)
{
    MapStringString ret = ConfigurationManager::instance()
                              .getConversationPreferences(owner.id, conversationId);
    return ret;
}

QString
ConversationModel::createConversation(const VectorString& participants, const MapStringString& infos)
{
    auto convUid = ConfigurationManager::instance().startConversation(owner.id);
    pimpl_->addSwarmConversation(convUid);
    if (!infos.isEmpty())
        updateConversationInfos(convUid, infos);
    for (const auto& participant : participants)
        ConfigurationManager::instance().addConversationMember(owner.id, convUid, participant);
    Q_EMIT newConversation(convUid);
    pimpl_->invalidateModel();
    Q_EMIT modelChanged();
    return convUid;
}

void
ConversationModel::updateConversationInfos(const QString& conversationId,
                                           const MapStringString infos)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;
    auto& conversation = conversationOpt->get();
    if (conversation.isCoreDialog()) {
        // If 1:1, we override a profile (as the peer will send their new profiles)
        auto peer = pimpl_->peersForConversation(conversation);
        if (!peer.isEmpty())
            owner.contactModel->updateContact(peer.at(0), infos);
        return;
    }
    MapStringString newInfos = infos;
    // Compress avatar as it will be sent in the conversation's request over the DHT
    if (infos.contains("avatar"))
        newInfos["avatar"] = storage::vcard::compressedAvatar(infos["avatar"]);
    ConfigurationManager::instance().updateConversationInfos(owner.id, conversationId, newInfos);
}

void
ConversationModel::popFrontError(const QString& conversationId)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;

    auto& conversation = conversationOpt->get();
    conversation.errors.pop_front();
    Q_EMIT onConversationErrorsUpdated(conversationId);
}

void
ConversationModel::ignoreActiveCall(const QString& conversationId,
                                    const QString& id,
                                    const QString& uri,
                                    const QString& device)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;

    auto& conversation = conversationOpt->get();
    MapStringString mapCall;
    mapCall["id"] = id;
    mapCall["uri"] = uri;
    mapCall["device"] = device;
    conversation.ignoredActiveCalls.push_back(mapCall);
    Q_EMIT activeCallsChanged(owner.id, conversationId);
}

void
ConversationModel::setConversationPreferences(const QString& conversationId,
                                              const MapStringString prefs)
{
    ConfigurationManager::instance().setConversationPreferences(owner.id, conversationId, prefs);
}

bool
ConversationModel::hasPendingRequests() const
{
    return pendingRequestCount() > 0;
}

int
ConversationModel::pendingRequestCount() const
{
    int pendingRequestCount = 0;
    std::for_each(pimpl_->conversations.begin(),
                  pimpl_->conversations.end(),
                  [&pendingRequestCount](const auto& c) { pendingRequestCount += c.isRequest; });
    return pendingRequestCount;
}

int
ConversationModel::notificationsCount() const
{
    int notificationsCount = 0;
    std::for_each(pimpl_->conversations.begin(),
                  pimpl_->conversations.end(),
                  [&notificationsCount](const auto& c) {
                      if (c.preferences["ignoreNotifications"] == "true") {
                          return;
                      }
                      if (c.isRequest)
                          notificationsCount += 1;
                      else {
                          notificationsCount += c.unreadMessages;
                      }
                  });
    return notificationsCount;
}

void
ConversationModel::reloadHistory() const
{
    std::for_each(pimpl_->conversations.begin(),
                  pimpl_->conversations.end(),
                  [&](const conversation::Info& c) {
                      c.interactions->reloadHistory();
                      Q_EMIT conversationUpdated(c.uid);
                      Q_EMIT dataChanged(pimpl_->indexOf(c.uid));
                  });
}

QString
ConversationModel::title(const QString& conversationId) const
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value()) {
        return {};
    }
    auto& conversation = conversationOpt->get();
    if (conversation.isCoreDialog()) {
        auto peer = pimpl_->peersForConversation(conversation);
        if (peer.isEmpty())
            return {};
        // In this case, we can just display contact name
        if (peer.at(0) == owner.profileInfo.uri)
            return QObject::tr("%1 (you)").arg(owner.accountModel->bestNameForAccount(owner.id));
        return owner.contactModel->bestNameForContact(peer.at(0));
    }
    if (conversation.infos["title"] != "") {
        return conversation.infos["title"];
    }
    // NOTE: Do not call any daemon method there as title() is called a lot for drawing
    QString title;
    auto idx = 0u;
    auto others = 0;
    for (const auto& member : conversation.participants) {
        QString name;
        if (member.uri == owner.profileInfo.uri) {
            name = QObject::tr("%1 (you)").arg(owner.accountModel->bestNameForAccount(owner.id));
        } else {
            name = owner.contactModel->bestNameForContact(member.uri);
        }
        if (title.length() + name.length() > 32) {
            // Avoid too long titles
            others += 1;
            continue;
        }
        title += name;
        idx += 1;
        if (idx != conversation.participants.size() || others != 0) {
            title += ", ";
        }
    }
    if (others != 0) {
        title += QString("+ %1").arg(others);
    }
    return title;
}

member::Role
ConversationModel::memberRole(const QString& conversationId, const QString& memberUri) const
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        throw std::out_of_range("Member out of range");
    auto& conversation = conversationOpt->get();
    for (const auto& p : conversation.participants) {
        if (p.uri == memberUri)
            return p.role;
    }
    throw std::out_of_range("Member out of range");
}

QString
ConversationModel::description(const QString& conversationId) const
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return {};
    auto& conversation = conversationOpt->get();
    if (conversation.isCoreDialog()) {
        auto peer = pimpl_->peersForConversation(conversation);
        if (peer.isEmpty())
            return {};
        return owner.contactModel->bestIdForContact(peer.front());
    }
    return conversation.infos["description"];
}

QString
ConversationModel::avatar(const QString& conversationId) const
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value()) {
        return {};
    }
    auto& conversation = conversationOpt->get();
    if (conversation.isCoreDialog()) {
        auto peer = pimpl_->peersForConversation(conversation);
        if (peer.isEmpty())
            return {};
        // In this case, we can just display contact name
        return owner.contactModel->avatar(peer.at(0));
    }
    // We need to strip the whitespace characters for the avatar
    // when it comes from the conversation info.
    return conversation.infos["avatar"].simplified();
}

void
ConversationModel::sendMessage(const QString& uid, const QString& body, const QString& parentId)
{
    try {
        auto& conversation = pimpl_->getConversationForUid(uid, true).get();
        if (!conversation.isLegacy()) {
            ConfigurationManager::instance().sendMessage(owner.id,
                                                         uid,
                                                         body,
                                                         parentId,
                                                         static_cast<int>(MessageFlag::Text));
            return;
        }

        auto& peers = pimpl_->peersForConversation(conversation);
        if (peers.isEmpty()) {
            // Should not
            qDebug() << "ConversationModel::sendMessage can't send a interaction to a conversation "
                        "with no participant";
            return;
        }
        auto convId = uid;
        auto& peerId = peers.front();
        bool isTemporary = peerId == convId || convId == "SEARCHSIP";

        auto cb = ([this, isTemporary, body, &conversation, parentId, convId](
                       QString conversationId) {
            if (pimpl_->indexOf(conversationId) < 0) {
                return;
            }
            auto& newConv = isTemporary ? pimpl_->getConversationForUid(conversationId).get()
                                        : conversation;

            if (newConv.isSwarm()) {
                ConfigurationManager::instance().sendMessage(owner.id,
                                                             conversationId,
                                                             body,
                                                             parentId,
                                                             static_cast<int>(MessageFlag::Text));
                return;
            }
            auto& peers = pimpl_->peersForConversation(newConv);
            if (peers.isEmpty()) {
                return;
            }

            uint64_t daemonMsgId = 0;
            auto status = interaction::Status::SENDING;
            auto convId = newConv.uid;

            QStringList callLists = CallManager::instance().getCallList(""); // no auto
            // workaround: sometimes, it may happen that the daemon delete a call, but lrc
            // don't. We check if the call is
            //             still valid every time the user want to send a message.
            if (not newConv.callId.isEmpty() and not callLists.contains(newConv.callId))
                newConv.callId.clear();

            if (not newConv.callId.isEmpty()
                and call::canSendSIPMessage(owner.callModel->getCall(newConv.callId))) {
                status = interaction::Status::UNKNOWN;
                owner.callModel->sendSipMessage(newConv.callId, body);

            } else {
                daemonMsgId = owner.contactModel->sendDhtMessage(peers.front(), body);
            }

            // Add interaction to database
            interaction::Info msg {owner.profileInfo.uri,
                                   body,
                                   std::time(nullptr),
                                   0,
                                   interaction::Type::TEXT,
                                   status,
                                   true};
            auto msgId = storage::addMessageToConversation(pimpl_->db, convId, msg);

            // Update conversation
            if (status == interaction::Status::SENDING) {
                // Because the daemon already give an id for the message, we need to store it.
                storage::addDaemonMsgId(pimpl_->db, msgId, toQString(daemonMsgId));
            }

            if (!newConv.interactions->append(msgId, msg)) {
                qWarning() << Q_FUNC_INFO << "Append failed: duplicate ID";
                return;
            }

            newConv.lastSelfMessageId = msgId;
            // Emit this signal for chatview in the client
            Q_EMIT newInteraction(convId, msgId, msg);
            // This conversation is now at the top of the list
            // The order has changed, informs the client to redraw the list
            pimpl_->invalidateModel();
            Q_EMIT modelChanged();
            Q_EMIT dataChanged(pimpl_->indexOf(convId));
        });

        if (isTemporary) {
            QMetaObject::Connection* const connection = new QMetaObject::Connection;
            *connection = connect(this,
                                  &ConversationModel::conversationReady,
                                  [cb, connection, convId](QString conversationId,
                                                           QString participantId) {
                                      if (participantId != convId && convId != "SEARCHSIP") {
                                          return;
                                      }
                                      cb(conversationId);
                                      QObject::disconnect(*connection);
                                      if (connection) {
                                          delete connection;
                                      }
                                  });
        }
        pimpl_->sendContactRequest(peerId);
        if (!isTemporary) {
            cb(convId);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "could not send message to not existing conversation";
    }
}

void
ConversationModel::editMessage(const QString& convId,
                               const QString& newBody,
                               const QString& messageId)
{
    auto conversationOpt = getConversationForUid(convId);
    if (!conversationOpt.has_value()) {
        return;
    }
    ConfigurationManager::instance().sendMessage(owner.id,
                                                 convId,
                                                 newBody,
                                                 messageId,
                                                 static_cast<int>(MessageFlag::Reply));
}

void
ConversationModel::reactMessage(const QString& convId,
                                const QString& emoji,
                                const QString& messageId)
{
    auto conversationOpt = getConversationForUid(convId);
    if (!conversationOpt.has_value()) {
        return;
    }
    ConfigurationManager::instance().sendMessage(owner.id,
                                                 convId,
                                                 emoji,
                                                 messageId,
                                                 static_cast<int>(MessageFlag::Reaction));
}

void
ConversationModel::refreshFilter()
{
    pimpl_->invalidateModel();
    Q_EMIT filterChanged();
}

void
ConversationModel::updateSearchStatus(const QString& status) const
{
    Q_EMIT searchStatusChanged(status);
}

void
ConversationModel::setFilter(const QString& filter)
{
    pimpl_->currentFilter = filter;
    pimpl_->invalidateModel();
    pimpl_->searchResults.clear();
    Q_EMIT searchResultUpdated();
    owner.contactModel->searchContact(filter);
    Q_EMIT filterChanged();
}

void
ConversationModel::setFilter(const FilterType& filter)
{
    // Switch between PENDING, RING and SIP contacts.
    pimpl_->typeFilter = filter;
    pimpl_->invalidateModel();
    Q_EMIT filterChanged();
}

void
ConversationModel::joinConversations(const QString& uidA, const QString& uidB)
{
    auto conversationAIdx = pimpl_->indexOf(uidA);
    auto conversationBIdx = pimpl_->indexOf(uidB);
    if (conversationAIdx == -1 || conversationBIdx == -1 || !owner.enabled)
        return;
    auto& conversationA = pimpl_->conversations[conversationAIdx];
    auto& conversationB = pimpl_->conversations[conversationBIdx];

    if (conversationA.callId.isEmpty() || conversationB.callId.isEmpty())
        return;

    if (conversationA.confId.isEmpty()) {
        if (conversationB.confId.isEmpty()) {
            owner.callModel->joinCalls(conversationA.callId, conversationB.callId);
        } else {
            owner.callModel->joinCalls(conversationA.callId, conversationB.confId);
            conversationA.confId = conversationB.confId;
        }
    } else {
        if (conversationB.confId.isEmpty()) {
            owner.callModel->joinCalls(conversationA.confId, conversationB.callId);
            conversationB.confId = conversationA.confId;
        } else {
            owner.callModel->joinCalls(conversationA.confId, conversationB.confId);
            conversationB.confId = conversationA.confId;
        }
    }
}

void
ConversationModel::clearHistory(const QString& uid)
{
    auto conversationIdx = pimpl_->indexOf(uid);
    if (conversationIdx == -1)
        return;

    auto& conversation = pimpl_->conversations.at(conversationIdx);
    // Remove all TEXT interactions from database
    storage::clearHistory(pimpl_->db, uid);
    // Update conversation
    conversation.interactions->clear();
    storage::getHistory(pimpl_->db,
                        conversation,
                        pimpl_->linked.owner.profileInfo.uri); // will contain "Conversation started"

    Q_EMIT modelChanged();
    Q_EMIT conversationCleared(uid);
    Q_EMIT dataChanged(conversationIdx);
}

bool
ConversationModel::isLastDisplayed(const QString& convId,
                                   const QString& interactionId,
                                   const QString participant)
{
    auto conversationIdx = pimpl_->indexOf(convId);
    try {
        auto& conversation = pimpl_->conversations.at(conversationIdx);
        return conversation.interactions->getRead(participant) == interactionId;
    } catch (const std::out_of_range& e) {
    }
    return false;
}

void
ConversationModel::clearAllHistory()
{
    storage::clearAllHistory(pimpl_->db);

    for (auto& conversation : pimpl_->conversations) {
        {
            if (conversation.isSwarm()) {
                // WARNING: clear all history is not implemented for swarm
                continue;
            }
            conversation.interactions->clear();
        }
        storage::getHistory(pimpl_->db, conversation, pimpl_->linked.owner.profileInfo.uri);
        Q_EMIT dataChanged(pimpl_->indexOf(conversation.uid));
    }
    Q_EMIT modelChanged();
}

void
ConversationModel::clearUnreadInteractions(const QString& convId)
{
    auto conversationOpt = getConversationForUid(convId);
    if (!conversationOpt.has_value()) {
        return;
    }
    auto& conversation = conversationOpt->get();
    bool updated = false;
    QString lastDisplayedId;
    if (conversation.isSwarm()) {
        updated = true;
        conversation.interactions->withLast(
            [&](const QString& id, interaction::Info&) { lastDisplayedId = id; });
    } else {
        conversation.interactions->forEach([&](const QString& id, interaction::Info& interaction) {
            if (interaction.isRead)
                return;
            updated = true;
            interaction.isRead = true;
            if (owner.profileInfo.type != profile::Type::SIP)
                lastDisplayedId = storage::getDaemonIdByInteractionId(pimpl_->db, id);
            storage::setInteractionRead(pimpl_->db, id);
        });
    }
    if (!lastDisplayedId.isEmpty()) {
        auto to = conversation.isSwarm()
                      ? "swarm:" + convId
                      : "jami:" + pimpl_->peersForConversation(conversation).front();
        ConfigurationManager::instance().setMessageDisplayed(owner.id, to, lastDisplayedId, 3);
    }
    if (updated) {
        conversation.unreadMessages = 0;
        pimpl_->invalidateModel();
        Q_EMIT conversationUpdated(convId);
        Q_EMIT dataChanged(pimpl_->indexOf(convId));
    }
}

int
ConversationModel::loadConversationMessages(const QString& conversationId, const int size)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value()) {
        return -1;
    }
    auto& conversation = conversationOpt->get();
    if (conversation.allMessagesLoaded) {
        return -1;
    }
    QString lastMsgId;
    conversation.interactions->withLast(
        [&lastMsgId](const QString& id, interaction::Info&) { lastMsgId = id; });
    return ConfigurationManager::instance().loadConversation(owner.id,
                                                             conversationId,
                                                             lastMsgId,
                                                             size);
}

void
ConversationModel::acceptConversationRequest(const QString& conversationId)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;
    auto& conversation = conversationOpt->get();
    auto& peers = pimpl_->peersForConversation(conversation);
    if (peers.isEmpty())
        return;

    if (conversation.isSwarm()) {
        conversation.needsSyncing = true;
        Q_EMIT conversationUpdated(conversation.uid);
        pimpl_->invalidateModel();
        Q_EMIT modelChanged();
        ConfigurationManager::instance().acceptConversationRequest(owner.id, conversationId);
    } else {
        pimpl_->sendContactRequest(peers.front());
        try {
            auto contact = owner.contactModel->getContact(peers.front());
            auto notAdded = contact.profileInfo.type == profile::Type::TEMPORARY
                            || contact.profileInfo.type == profile::Type::PENDING;
            if (notAdded) {
                owner.contactModel->addContact(contact);
                return;
            }
        } catch (std::out_of_range& e) {
            qWarning() << e.what();
        }
    }
}

const VectorString
ConversationModel::peersForConversation(const QString& conversationId)
{
    const auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value()) {
        return {};
    }
    const auto& conversation = conversationOpt->get();
    return pimpl_->peersForConversation(conversation);
}

void
ConversationModel::addConversationMember(const QString& conversationId, const QString& memberId)
{
    ConfigurationManager::instance().addConversationMember(owner.id, conversationId, memberId);
}

void
ConversationModel::removeConversationMember(const QString& conversationId, const QString& memberId)
{
    ConfigurationManager::instance().removeConversationMember(owner.id, conversationId, memberId);
}

ConversationModelPimpl::ConversationModelPimpl(const ConversationModel& linked,
                                               Lrc& lrc,
                                               Database& db,
                                               const CallbacksHandler& callbacksHandler,
                                               const BehaviorController& behaviorController)
    : linked(linked)
    , lrc {lrc}
    , db(db)
    , callbacksHandler(callbacksHandler)
    , typeFilter(FilterType::INVALID)
    , customTypeFilter(FilterType::INVALID)
    , behaviorController(behaviorController)
{
    filteredConversations.bindSortCallback(this, &ConversationModelPimpl::sort);
    filteredConversations.bindFilterCallback(this, &ConversationModelPimpl::filter);

    initConversations();

    // Contact related
    connect(&*linked.owner.contactModel,
            &ContactModel::modelUpdated,
            this,
            &ConversationModelPimpl::slotContactModelUpdated);
    connect(&*linked.owner.contactModel,
            &ContactModel::contactAdded,
            this,
            &ConversationModelPimpl::slotContactAdded);
    connect(&*linked.owner.contactModel,
            &ContactModel::pendingContactAccepted,
            this,
            &ConversationModelPimpl::slotPendingContactAccepted);
    connect(&*linked.owner.contactModel,
            &ContactModel::contactRemoved,
            this,
            &ConversationModelPimpl::slotContactRemoved);

    // Messages related
    connect(&*linked.owner.contactModel,
            &lrc::ContactModel::newAccountMessage,
            this,
            &ConversationModelPimpl::slotNewAccountMessage);
    connect(&callbacksHandler,
            &CallbacksHandler::incomingCallMessage,
            this,
            &ConversationModelPimpl::slotIncomingCallMessage);
    connect(&callbacksHandler,
            &CallbacksHandler::accountMessageStatusChanged,
            this,
            &ConversationModelPimpl::updateInteractionStatus);

    // Call related
    connect(&*linked.owner.contactModel,
            &ContactModel::newCall,
            this,
            &ConversationModelPimpl::slotNewCall);
    connect(&*linked.owner.callModel,
            &lrc::api::CallModel::callStatusChanged,
            this,
            &ConversationModelPimpl::slotCallStatusChanged);
    connect(&*linked.owner.callModel,
            &lrc::api::CallModel::callStarted,
            this,
            &ConversationModelPimpl::slotCallStarted);
    connect(&*linked.owner.callModel,
            &lrc::api::CallModel::callEnded,
            this,
            &ConversationModelPimpl::slotCallEnded);
    connect(&*linked.owner.callModel,
            &lrc::api::CallModel::callAddedToConference,
            this,
            &ConversationModelPimpl::slotCallAddedToConference);
    connect(&callbacksHandler,
            &CallbacksHandler::conferenceRemoved,
            this,
            &ConversationModelPimpl::slotConferenceRemoved);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::composingStatusChanged,
            this,
            &ConversationModelPimpl::slotComposingStatusChanged);
    connect(&callbacksHandler, &CallbacksHandler::needsHost, this, [&](auto, auto convId) {
        emit linked.needsHost(convId);
    });

    // data transfer
    connect(&*linked.owner.contactModel,
            &ContactModel::newAccountTransfer,
            this,
            &ConversationModelPimpl::slotTransferStatusCreated);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusCanceled,
            this,
            &ConversationModelPimpl::slotTransferStatusCanceled);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusAwaitingPeer,
            this,
            &ConversationModelPimpl::slotTransferStatusAwaitingPeer);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusAwaitingHost,
            this,
            &ConversationModelPimpl::slotTransferStatusAwaitingHost);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusOngoing,
            this,
            &ConversationModelPimpl::slotTransferStatusOngoing);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusFinished,
            this,
            &ConversationModelPimpl::slotTransferStatusFinished);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusError,
            this,
            &ConversationModelPimpl::slotTransferStatusError);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusTimeoutExpired,
            this,
            &ConversationModelPimpl::slotTransferStatusTimeoutExpired);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusUnjoinable,
            this,
            &ConversationModelPimpl::slotTransferStatusUnjoinable);
    // swarm conversations
    connect(&callbacksHandler,
            &CallbacksHandler::swarmLoaded,
            this,
            &ConversationModelPimpl::slotSwarmLoaded);
    connect(&callbacksHandler,
            &CallbacksHandler::messagesFound,
            this,
            &ConversationModelPimpl::slotMessagesFound);
    connect(&callbacksHandler,
            &CallbacksHandler::messageReceived,
            this,
            &ConversationModelPimpl::slotMessageReceived);
    connect(&callbacksHandler,
            &CallbacksHandler::messageUpdated,
            this,
            &ConversationModelPimpl::slotMessageUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::reactionAdded,
            this,
            &ConversationModelPimpl::slotReactionAdded);
    connect(&callbacksHandler,
            &CallbacksHandler::reactionRemoved,
            this,
            &ConversationModelPimpl::slotReactionRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationProfileUpdated,
            this,
            &ConversationModelPimpl::slotConversationProfileUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRequestReceived,
            this,
            &ConversationModelPimpl::slotConversationRequestReceived);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRequestDeclined,
            this,
            &ConversationModelPimpl::slotConversationRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationReady,
            this,
            &ConversationModelPimpl::slotConversationReady);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRemoved,
            this,
            &ConversationModelPimpl::slotConversationRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationMemberEvent,
            this,
            &ConversationModelPimpl::slotConversationMemberEvent);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationError,
            this,
            &ConversationModelPimpl::slotOnConversationError);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationPreferencesUpdated,
            this,
            &ConversationModelPimpl::slotConversationPreferencesUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::activeCallsChanged,
            this,
            &ConversationModelPimpl::slotActiveCallsChanged);
}

ConversationModelPimpl::~ConversationModelPimpl()
{
    // Contact related
    disconnect(&*linked.owner.contactModel,
               &ContactModel::modelUpdated,
               this,
               &ConversationModelPimpl::slotContactModelUpdated);
    disconnect(&*linked.owner.contactModel,
               &ContactModel::contactAdded,
               this,
               &ConversationModelPimpl::slotContactAdded);
    disconnect(&*linked.owner.contactModel,
               &ContactModel::pendingContactAccepted,
               this,
               &ConversationModelPimpl::slotPendingContactAccepted);
    disconnect(&*linked.owner.contactModel,
               &ContactModel::contactRemoved,
               this,
               &ConversationModelPimpl::slotContactRemoved);

    // Messages related
    disconnect(&*linked.owner.contactModel,
               &lrc::ContactModel::newAccountMessage,
               this,
               &ConversationModelPimpl::slotNewAccountMessage);
    disconnect(&callbacksHandler,
               &CallbacksHandler::incomingCallMessage,
               this,
               &ConversationModelPimpl::slotIncomingCallMessage);
    disconnect(&callbacksHandler,
               &CallbacksHandler::accountMessageStatusChanged,
               this,
               &ConversationModelPimpl::updateInteractionStatus);

    // Call related
    disconnect(&*linked.owner.contactModel,
               &ContactModel::newCall,
               this,
               &ConversationModelPimpl::slotNewCall);
    disconnect(&*linked.owner.callModel,
               &lrc::api::CallModel::callStatusChanged,
               this,
               &ConversationModelPimpl::slotCallStatusChanged);
    disconnect(&*linked.owner.callModel,
               &lrc::api::CallModel::callStarted,
               this,
               &ConversationModelPimpl::slotCallStarted);
    disconnect(&*linked.owner.callModel,
               &lrc::api::CallModel::callEnded,
               this,
               &ConversationModelPimpl::slotCallEnded);
    disconnect(&*linked.owner.callModel,
               &lrc::api::CallModel::callAddedToConference,
               this,
               &ConversationModelPimpl::slotCallAddedToConference);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conferenceRemoved,
               this,
               &ConversationModelPimpl::slotConferenceRemoved);
    disconnect(&ConfigurationManager::instance(),
               &ConfigurationManagerInterface::composingStatusChanged,
               this,
               &ConversationModelPimpl::slotComposingStatusChanged);

    // data transfer
    disconnect(&*linked.owner.contactModel,
               &ContactModel::newAccountTransfer,
               this,
               &ConversationModelPimpl::slotTransferStatusCreated);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusCanceled,
               this,
               &ConversationModelPimpl::slotTransferStatusCanceled);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusAwaitingPeer,
               this,
               &ConversationModelPimpl::slotTransferStatusAwaitingPeer);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusAwaitingHost,
               this,
               &ConversationModelPimpl::slotTransferStatusAwaitingHost);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusOngoing,
               this,
               &ConversationModelPimpl::slotTransferStatusOngoing);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusFinished,
               this,
               &ConversationModelPimpl::slotTransferStatusFinished);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusError,
               this,
               &ConversationModelPimpl::slotTransferStatusError);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusTimeoutExpired,
               this,
               &ConversationModelPimpl::slotTransferStatusTimeoutExpired);
    disconnect(&callbacksHandler,
               &CallbacksHandler::transferStatusUnjoinable,
               this,
               &ConversationModelPimpl::slotTransferStatusUnjoinable);
    // swarm conversations
    disconnect(&callbacksHandler,
               &CallbacksHandler::swarmLoaded,
               this,
               &ConversationModelPimpl::slotSwarmLoaded);
    disconnect(&callbacksHandler,
               &CallbacksHandler::messagesFound,
               this,
               &ConversationModelPimpl::slotMessagesFound);
    disconnect(&callbacksHandler,
               &CallbacksHandler::messageReceived,
               this,
               &ConversationModelPimpl::slotMessageReceived);
    disconnect(&callbacksHandler,
               &CallbacksHandler::messageUpdated,
               this,
               &ConversationModelPimpl::slotMessageUpdated);
    disconnect(&callbacksHandler,
               &CallbacksHandler::reactionAdded,
               this,
               &ConversationModelPimpl::slotReactionAdded);
    disconnect(&callbacksHandler,
               &CallbacksHandler::reactionRemoved,
               this,
               &ConversationModelPimpl::slotReactionRemoved);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationProfileUpdated,
               this,
               &ConversationModelPimpl::slotConversationProfileUpdated);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationRequestReceived,
               this,
               &ConversationModelPimpl::slotConversationRequestReceived);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationRequestDeclined,
               this,
               &ConversationModelPimpl::slotConversationRemoved);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationReady,
               this,
               &ConversationModelPimpl::slotConversationReady);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationRemoved,
               this,
               &ConversationModelPimpl::slotConversationRemoved);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationMemberEvent,
               this,
               &ConversationModelPimpl::slotConversationMemberEvent);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationError,
               this,
               &ConversationModelPimpl::slotOnConversationError);
    disconnect(&callbacksHandler,
               &CallbacksHandler::activeCallsChanged,
               this,
               &ConversationModelPimpl::slotActiveCallsChanged);
    disconnect(&callbacksHandler,
               &CallbacksHandler::conversationPreferencesUpdated,
               this,
               &ConversationModelPimpl::slotConversationPreferencesUpdated);
}

void
ConversationModelPimpl::initConversations()
{
    const MapStringString accountDetails = ConfigurationManager::instance().getAccountDetails(
        linked.owner.id);
    if (accountDetails.empty())
        return;

    // Fill swarm conversations
    QStringList swarms = ConfigurationManager::instance().getConversations(linked.owner.id);
    for (auto& swarmConv : swarms) {
        addSwarmConversation(swarmConv);
    }

    VectorMapStringString conversationsRequests = ConfigurationManager::instance()
                                                      .getConversationRequests(linked.owner.id);
    for (auto& request : conversationsRequests) {
        addConversationRequest(request);
    }

    // Fill conversations
    for (auto const& c : linked.owner.contactModel->getAllContacts().toStdMap()) {
        auto conv = storage::getConversationsWithPeer(db, c.second.profileInfo.uri);
        if (hasOneOneSwarmWith(c.second.profileInfo.uri))
            continue;
        bool isRequest = c.second.profileInfo.type == profile::Type::PENDING;
        if (conv.empty()) {
            // Can't find a conversation with this contact
            // add pending not swarm conversation
            if (isRequest) {
                addContactRequest(c.second.profileInfo.uri);
                continue;
            }
            conv.push_back(storage::beginConversationWithPeer(db,
                                                              c.second.profileInfo.uri,
                                                              true,
                                                              linked.owner.contactModel->getAddedTs(
                                                                  c.second.profileInfo.uri)));
        }
        addConversationWith(conv[0], c.first, isRequest);

        auto convIdx = indexOf(conv[0]);

        // Resolve any file transfer interactions were left in an incorrect state
        auto& interactions = conversations[convIdx].interactions;
        interactions->forEach([&](const QString& id, interaction::Info& interaction) {
            if (interaction.status == interaction::Status::TRANSFER_CREATED
                || interaction.status == interaction::Status::TRANSFER_AWAITING_HOST
                || interaction.status == interaction::Status::TRANSFER_AWAITING_PEER
                || interaction.status == interaction::Status::TRANSFER_ONGOING
                || interaction.status == interaction::Status::TRANSFER_ACCEPTED) {
                // If a datatransfer was left in a non-terminal status in DB, we switch this status
                // to ERROR
                // TODO : Improve for DBus clients as daemon and transfer may still be ongoing
                storage::updateInteractionStatus(db, id, interaction::Status::TRANSFER_ERROR);

                interaction.status = interaction::Status::TRANSFER_ERROR;
            }
        });
    }
    invalidateModel();

    filteredConversations.reset(conversations).sort();

    // Load all non treated messages for this account
    QVector<Message> messages = ConfigurationManager::instance()
                                    .getLastMessages(linked.owner.id, storage::getLastTimestamp(db));
    for (const auto& message : messages) {
        uint64_t timestamp = 0;
        try {
            timestamp = static_cast<uint64_t>(message.received);
        } catch (...) {
        }
        addIncomingMessage(message.from, message.payloads[TEXT_PLAIN], timestamp);
    }
}

const VectorString
ConversationModelPimpl::peersForConversation(const conversation::Info& conversation) const
{
    VectorString result {};
    switch (conversation.mode) {
    case conversation::Mode::NON_SWARM:
        return {conversation.participants[0].uri};
    default:
        break;
    }
    // Note: for one to one, we must return self
    if (conversation.participants.size() == 1)
        return {conversation.participants[0].uri};
    for (const auto& participant : conversation.participants) {
        if (participant.uri.isNull())
            continue;
        if (participant.uri != linked.owner.profileInfo.uri)
            result.push_back(participant.uri);
    }
    return result;
}

bool
ConversationModelPimpl::filter(const conversation::Info& entry)
{
    try {
        // TODO: filter for group?
        // for now group conversation filtered by first peer
        auto& peers = peersForConversation(entry);
        if (peers.size() < 1) {
            return false;
        }
        auto uriPeer = peers.front();
        contact::Info contactInfo;
        try {
            contactInfo = linked.owner.contactModel->getContact(uriPeer);
        } catch (...) {
            // Note: as we search for contacts, when importing a new account,
            // the conversation's request can be there without contact, causing
            // the function to fail.
            contactInfo.profileInfo.uri = uriPeer;
        }

        auto uri = URI(currentFilter);
        bool stripScheme = (uri.schemeType() < URI::SchemeType::COUNT__);
        FlagPack<URI::Section> flags = URI::Section::USER_INFO | URI::Section::HOSTNAME
                                       | URI::Section::PORT;
        if (!stripScheme) {
            flags |= URI::Section::SCHEME;
        }

        currentFilter = uri.format(flags);

        // Check contact
        // If contact is banned, only match if filter is a perfect match
        // do not check banned contact for conversation with multiple participants
        if (contactInfo.isBanned && peers.size() == 1) {
            if (currentFilter == "")
                return false;
            return contactInfo.profileInfo.uri == currentFilter
                   || contactInfo.profileInfo.alias == currentFilter
                   || contactInfo.registeredName == currentFilter;
        }

        std::regex regexFilter;
        auto isValidReFilter = true;
        try {
            regexFilter = std::regex(currentFilter.toStdString(), std::regex_constants::icase);
        } catch (std::regex_error&) {
            isValidReFilter = false;
        }

        auto filterUriAndReg = [regexFilter, isValidReFilter](auto contact, auto filter) {
            auto result = contact.profileInfo.uri.contains(filter)
                          || contact.registeredName.contains(filter);
            if (!result) {
                auto regexFound = isValidReFilter
                                      ? (!contact.profileInfo.uri.isEmpty()
                                         && std::regex_search(contact.profileInfo.uri.toStdString(),
                                                              regexFilter))
                                            || std::regex_search(contact.registeredName.toStdString(),
                                                                 regexFilter)
                                      : false;
                result |= regexFound;
            }
            return result;
        };

        // Check type
        switch (typeFilter) {
        case FilterType::JAMI:
        case FilterType::SIP:
            if (entry.isRequest)
                return false;
            if (contactInfo.profileInfo.type == profile::Type::TEMPORARY)
                return filterUriAndReg(contactInfo, currentFilter);
            break;
        case FilterType::REQUEST:
            if (!entry.isRequest)
                return false;
            break;
        default:
            break;
        }

        // Otherwise perform usual regex search
        bool result = contactInfo.profileInfo.alias.contains(currentFilter);
        if (!result && isValidReFilter)
            result |= std::regex_search(contactInfo.profileInfo.alias.toStdString(), regexFilter);
        if (!result)
            result |= filterUriAndReg(contactInfo, currentFilter);
        return result;
    } catch (std::out_of_range&) {
        // getContact() failed
        return false;
    }
}

bool
ConversationModelPimpl::sort(const conversation::Info& convA, const conversation::Info& convB)
{
    // A or B is a temporary contact
    if (convA.participants.isEmpty())
        return true;
    if (convB.participants.isEmpty())
        return false;

    if (convA.uid == convB.uid)
        return false;

    auto& historyA = convA.interactions;
    auto& historyB = convB.interactions;

    std::lock(historyA->getMutex(), historyB->getMutex());
    std::lock_guard<std::recursive_mutex> lockConvA(historyA->getMutex(), std::adopt_lock);
    std::lock_guard<std::recursive_mutex> lockConvB(historyB->getMutex(), std::adopt_lock);

    // A or B is a new conversation (without CONTACT interaction)
    if (convA.uid.isEmpty() || convB.uid.isEmpty())
        return convA.uid.isEmpty();

    if (historyA->empty() && historyB->empty()) {
        // If no information to compare, sort by Ring ID. For group conversation sort by first peer
        auto& peersForA = peersForConversation(convA);
        auto& peersForB = peersForConversation(convB);
        if (peersForA.isEmpty()) {
            return false;
        }
        if (peersForB.isEmpty()) {
            return true;
        }
        return peersForA.front() > peersForB.front();
    }
    if (historyA->empty())
        return false;
    if (historyB->empty())
        return true;
    // Sort by last Interaction
    time_t timestampA, timestampB;
    historyA->withLast([&](const QString&, const interaction::Info& interaction) {
        timestampA = interaction.timestamp;
    });
    historyB->withLast([&](const QString&, const interaction::Info& interaction) {
        timestampB = interaction.timestamp;
    });
    return timestampA > timestampB;
}

void
ConversationModelPimpl::sendContactRequest(const QString& contactUri)
{
    try {
        auto contact = linked.owner.contactModel->getContact(contactUri);
        auto isNotUsed = contact.profileInfo.type == profile::Type::TEMPORARY
                         || contact.profileInfo.type == profile::Type::PENDING;
        if (isNotUsed)
            linked.owner.contactModel->addContact(contact);
    } catch (std::out_of_range& e) {
    }
}

void
ConversationModelPimpl::slotSwarmLoaded(uint32_t requestId,
                                        const QString& accountId,
                                        const QString& conversationId,
                                        const VectorSwarmMessage& messages)
{
    if (accountId != linked.owner.id)
        return;
    auto allLoaded = false;
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        for (const auto& message : messages) {
            QString msgId = message.id;
            auto msg = interaction::Info(message, linked.owner.profileInfo.uri);
            auto downloadFile = false;
            if (msg.type == interaction::Type::INITIAL) {
                allLoaded = true;
            } else if (msg.type == interaction::Type::DATA_TRANSFER) {
                QString fileId = message.body.value("fileId");
                QString path;
                qlonglong bytesProgress, totalSize;
                linked.owner.dataTransferModel->fileTransferInfo(accountId,
                                                                 conversationId,
                                                                 fileId,
                                                                 path,
                                                                 totalSize,
                                                                 bytesProgress);
                QFileInfo fi(path);
                if (fi.isSymLink()) {
                    msg.body = fi.symLinkTarget();
                } else {
                    msg.body = path;
                }
                msg.status = bytesProgress == 0 ? interaction::Status::TRANSFER_AWAITING_HOST
                             : bytesProgress == totalSize ? interaction::Status::TRANSFER_FINISHED
                                                          : interaction::Status::TRANSFER_ONGOING;
                linked.owner.dataTransferModel->registerTransferId(fileId, msgId);
                downloadFile = (bytesProgress == 0);
            }

            // If message is loaded, insert message at beginning
            if (!conversation.interactions->insert(msgId, msg, 0)) {
                qDebug() << Q_FUNC_INFO << "Insert failed: duplicate ID";
                continue;
            }

            if (downloadFile) {
                handleIncomingFile(conversationId,
                                   msgId,
                                   QString(message.body.value("totalSize")).toInt());
            }
        }

        conversation.lastSelfMessageId = conversation.interactions->lastSelfMessageId(
            linked.owner.profileInfo.uri);
        invalidateModel();
        Q_EMIT linked.modelChanged();
        Q_EMIT linked.newMessagesAvailable(linked.owner.id, conversationId);
        auto conversationIdx = indexOf(conversationId);
        Q_EMIT linked.dataChanged(conversationIdx);
        Q_EMIT linked.conversationMessagesLoaded(requestId, conversationId);
        if (allLoaded) {
            conversation.allMessagesLoaded = true;
            Q_EMIT linked.conversationUpdated(conversationId);
        }
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
ConversationModelPimpl::slotMessagesFound(uint32_t requestId,
                                          const QString& accountId,
                                          const QString& conversationId,
                                          const VectorMapStringString& messageIds)
{
    QMap<QString, interaction::Info> messageDetailedInformation;
    if (requestId == mediaResearchRequestId) {
        Q_FOREACH (const MapStringString& msg, messageIds) {
            auto intInfo = interaction::Info(msg, "");
            if (intInfo.type == interaction::Type::DATA_TRANSFER) {
                auto fileId = msg["fileId"];

                QString path;
                qlonglong bytesProgress, totalSize;
                linked.owner.dataTransferModel->fileTransferInfo(accountId,
                                                                 conversationId,
                                                                 fileId,
                                                                 path,
                                                                 totalSize,
                                                                 bytesProgress);
                intInfo.body = path;
            }
            messageDetailedInformation[msg["id"]] = std::move(intInfo);
        }
    } else if (requestId == msgResearchRequestId) {
        Q_FOREACH (const MapStringString& msg, messageIds) {
            auto intInfo = interaction::Info(msg, "");
            if (intInfo.type == interaction::Type::TEXT) {
                messageDetailedInformation[msg["id"]] = std::move(intInfo);
            }
        }
    }
    Q_EMIT linked.messagesFoundProcessed(accountId, messageDetailedInformation);
}

void
ConversationModelPimpl::slotMessageReceived(const QString& accountId,
                                            const QString& conversationId,
                                            const SwarmMessage& message)
{
    if (accountId != linked.owner.id)
        return;
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        if (message.type == "initial") {
            conversation.allMessagesLoaded = true;
            Q_EMIT linked.conversationUpdated(conversationId);
            if (message.body.find("invited") == message.body.end()) {
                return;
            }
        }
        QString msgId = message.id;
        auto msg = interaction::Info(message, linked.owner.profileInfo.uri);

        if (msg.type == interaction::Type::CALL) {
            msg.body = interaction::getCallInteractionString(msg.authorUri
                                                                 == linked.owner.profileInfo.uri,
                                                             msg);
        } else if (msg.type == interaction::Type::DATA_TRANSFER) {
            // save data transfer interaction to db and assosiate daemon id with interaction id,
            // conversation id and db id
            QString fileId = message.body.value("fileId");
            QString path;
            qlonglong bytesProgress, totalSize;
            linked.owner.dataTransferModel->fileTransferInfo(accountId,
                                                             conversationId,
                                                             fileId,
                                                             path,
                                                             totalSize,
                                                             bytesProgress);
            QFileInfo fi(path);
            if (fi.isSymLink()) {
                msg.body = fi.symLinkTarget();
            } else {
                msg.body = path;
            }
            msg.status = bytesProgress == 0           ? interaction::Status::TRANSFER_AWAITING_HOST
                         : bytesProgress == totalSize ? interaction::Status::TRANSFER_FINISHED
                                                      : interaction::Status::TRANSFER_ONGOING;
            linked.owner.dataTransferModel->registerTransferId(fileId, msgId);
        }

        if (!conversation.interactions->append(msgId, msg)) {
            qDebug() << Q_FUNC_INFO << "Append failed: duplicate ID" << msgId;
            return;
        }

        auto updateUnread = msg.authorUri != linked.owner.profileInfo.uri;
        if (updateUnread)
            conversation.unreadMessages++;
        conversation.lastSelfMessageId = conversation.interactions->lastSelfMessageId(
            linked.owner.profileInfo.uri);
        invalidateModel();
        if (!interaction::isOutgoing(msg) && updateUnread) {
            Q_EMIT behaviorController.newUnreadInteraction(linked.owner.id,
                                                           conversationId,
                                                           msgId,
                                                           msg);
        }
        Q_EMIT linked.newInteraction(conversationId, msgId, msg);
        Q_EMIT linked.modelChanged();
        if (msg.status == interaction::Status::TRANSFER_AWAITING_HOST && updateUnread) {
            handleIncomingFile(conversationId,
                               msgId,
                               QString(message.body.value("totalSize")).toInt());
        }
        Q_EMIT linked.dataChanged(indexOf(conversationId));
        // Update status
        using namespace libjami::Account;
        for (const auto& uri : message.status.keys()) {
            if (uri == linked.owner.profileInfo.uri)
                continue;
            if (message.status.value(uri) == static_cast<int>(MessageStates::DISPLAYED))
                conversation.interactions->setRead(uri, message.id);
        }
    } catch (const std::exception& e) {
        qDebug() << "messages received for not existing conversation";
    }
}

void
ConversationModelPimpl::slotMessageUpdated(const QString& accountId,
                                           const QString& conversationId,
                                           const SwarmMessage& message)
{
    if (accountId != linked.owner.id)
        return;
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        QString msgId = message.id;
        auto msg = interaction::Info(message, linked.owner.profileInfo.uri);

        if (!conversation.interactions->update(msgId, msg)) {
            qDebug() << "message not found or could not be reparented";
            return;
        }
        // The conversation is updated, so we need to notify the view.
        invalidateModel();
        Q_EMIT linked.modelChanged();
        Q_EMIT linked.dataChanged(indexOf(conversationId));
    } catch (const std::exception& e) {
        qDebug() << "messages received for not existing conversation";
    }
}

void
ConversationModelPimpl::slotReactionAdded(const QString& accountId,
                                          const QString& conversationId,
                                          const QString& messageId,
                                          const MapStringString& reaction)
{
    if (accountId != linked.owner.id) {
        return;
    }
    try {
        // qInfo() << "Add Reaction to " << messageId << " in " << conversationId;
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.interactions->addReaction(messageId, reaction);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
ConversationModelPimpl::slotReactionRemoved(const QString& accountId,
                                            const QString& conversationId,
                                            const QString& messageId,
                                            const QString& reactionId)
{
    if (accountId != linked.owner.id) {
        return;
    }
    try {
        // qInfo() << "Remove Reaction from " << messageId << " in " << conversationId;
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.interactions->rmReaction(messageId, reactionId);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
ConversationModelPimpl::slotConversationProfileUpdated(const QString& accountId,
                                                       const QString& conversationId,
                                                       const MapStringString& profile)
{
    if (accountId != linked.owner.id) {
        return;
    }
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.infos = profile;
        Q_EMIT linked.profileUpdated(conversationId);
    } catch (...) {
    }
}

void
ConversationModelPimpl::slotConversationRequestReceived(const QString& accountId,
                                                        const QString&,
                                                        const MapStringString& metadatas)
{
    if (accountId != linked.owner.id)
        return;
    addConversationRequest(metadatas, true);
}

void
ConversationModelPimpl::slotConversationReady(const QString& accountId,
                                              const QString& conversationId)
{
    // we receive this signal after we accept or after we send a conversation request
    if (accountId != linked.owner.id) {
        return;
    }
    // remove non swarm conversation that was added from slotContactAdded
    const VectorMapStringString& members = ConfigurationManager::instance()
                                               .getConversationMembers(accountId, conversationId);
    QVector<member::Member> participants;
    // it means conversation with one participant. In this case we could have non swarm conversation
    bool shouldRemoveNonSwarmConversation = members.size() == 2;
    for (const auto& member : members) {
        participants.append({member["uri"], api::member::to_role(member["role"])});
        if (shouldRemoveNonSwarmConversation) {
            try {
                auto& conversation = getConversationForPeerUri(member["uri"]).get();
                // remove non swarm conversation
                if (conversation.isLegacy()) {
                    eraseConversation(conversation.uid);
                    storage::removeContactConversations(db, member["uri"]);
                    invalidateModel();
                    Q_EMIT linked.conversationRemoved(conversation.uid);
                    Q_EMIT linked.modelChanged();
                }
            } catch (...) {
            }
        }
    }

    int conversationIdx = indexOf(conversationId);
    bool conversationExists = conversationIdx >= 0;

    if (!conversationExists)
        addSwarmConversation(conversationId);
    auto& conversation = getConversationForUid(conversationId).get();
    if (conversationExists) {
        // if swarm request already exists, update participnts
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.participants = participants;
        const MapStringString& details = ConfigurationManager::instance()
                                             .conversationInfos(accountId, conversationId);
        conversation.infos = details;
        const MapStringString& preferences
            = ConfigurationManager::instance().getConversationPreferences(accountId, conversationId);
        conversation.preferences = preferences;
        conversation.mode = conversation::to_mode(details["mode"].toInt());
        conversation.isRequest = false;
        conversation.needsSyncing = false;
        Q_EMIT linked.conversationUpdated(conversationId);
        Q_EMIT linked.dataChanged(conversationIdx);
        ConfigurationManager::instance().loadConversation(linked.owner.id, conversationId, "", 0);
        auto& peers = peersForConversation(conversation);
        if (peers.size() == 1)
            Q_EMIT linked.conversationReady(conversationId, peers.front());
        return;
    }
    invalidateModel();
    // we use conversationReady callback only for conversation with one participant. We could use
    // participants.front()
    auto& peers = peersForConversation(conversation);
    if (peers.size() == 1)
        Q_EMIT linked.conversationReady(conversationId, peers.front());
    Q_EMIT linked.newConversation(conversationId);
    Q_EMIT linked.modelChanged();
}

void
ConversationModelPimpl::slotConversationRemoved(const QString& accountId,
                                                const QString& conversationId)
{
    auto conversationIndex = indexOf(conversationId);
    if (accountId != linked.owner.id || conversationIndex < 0)
        return;
    try {
        auto removeConversation = [&]() {
            // remove swarm conversation
            eraseConversation(conversationIndex);
            invalidateModel();
            Q_EMIT linked.conversationRemoved(conversationId);
        };

        auto& conversation = getConversationForUid(conversationId).get();
        auto& peers = peersForConversation(conversation);
        if (peers.isEmpty()) {
            removeConversation();
            return;
        }
        auto contactUri = peers.first();
        auto mode = conversation.mode;
        contact::Info contact;
        try {
            contact = linked.owner.contactModel->getContact(contactUri);
        } catch (...) {
        }

        removeConversation();

        if (mode == conversation::Mode::ONE_TO_ONE) {
            // If it's a 1:1 conversation and we don't have any more conversation
            // we can remove the contact
            auto contactRemoved = true;
            try {
                auto& conv = getConversationForPeerUri(contactUri).get();
                contactRemoved = !conv.isSwarm();
            } catch (...) {
            }

            if (contact.isBanned && contactRemoved) {
                // Add 1:1 conv for banned
                auto c = storage::beginConversationWithPeer(db, contactUri);
                addConversationWith(c, contactUri, false);
                Q_EMIT linked.conversationReady(c, contactUri);
                Q_EMIT linked.newConversation(c);
            }
        }

    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
ConversationModelPimpl::slotConversationMemberEvent(const QString& accountId,
                                                    const QString& conversationId,
                                                    const QString& memberUri,
                                                    int event)
{
    if (accountId != linked.owner.id || indexOf(conversationId) < 0) {
        return;
    }
    if (event == 0 /* add */) {
        // clear search result
        for (unsigned int i = 0; i < searchResults.size(); ++i) {
            if (searchResults.at(i).uid == memberUri)
                searchResults.erase(searchResults.begin() + i);
        }
    }
    // update participants
    auto& conversation = getConversationForUid(conversationId).get();
    const VectorMapStringString& members
        = ConfigurationManager::instance().getConversationMembers(linked.owner.id, conversationId);
    QVector<member::Member> participants;
    VectorString membersRemaining;
    for (auto& member : members) {
        participants.append(member::Member {member["uri"], member::to_role(member["role"])});
        if (member["role"] != "left")
            membersRemaining.append(member["uri"]);
    }
    conversation.participants = participants;
    invalidateModel();
    Q_EMIT linked.modelChanged();
    Q_EMIT linked.conversationUpdated(conversationId);
    Q_EMIT linked.dataChanged(indexOf(conversationId));
}

void
ConversationModelPimpl::slotOnConversationError(const QString& accountId,
                                                const QString& conversationId,
                                                int code,
                                                const QString& what)
{
    if (accountId != linked.owner.id || indexOf(conversationId) < 0) {
        return;
    }
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.errors.push_back({code, what});
        Q_EMIT linked.onConversationErrorsUpdated(conversationId);
    } catch (...) {
    }
}

void
ConversationModelPimpl::slotActiveCallsChanged(const QString& accountId,
                                               const QString& conversationId,
                                               const VectorMapStringString& activeCalls)
{
    if (accountId != linked.owner.id || indexOf(conversationId) < 0) {
        return;
    }
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        conversation.activeCalls = activeCalls;
        if (activeCalls.empty())
            conversation.ignoredActiveCalls.clear();
        Q_EMIT linked.activeCallsChanged(accountId, conversationId);
    } catch (...) {
    }
}

void
ConversationModelPimpl::slotContactAdded(const QString& contactUri)
{
    QString convId;
    try {
        convId = linked.owner.contactModel->getContact(contactUri).conversationId;
    } catch (std::out_of_range& e) {
        return;
    }

    auto isSwarm = !convId.isEmpty();
    auto conv = !isSwarm ? storage::getConversationsWithPeer(db, contactUri)
                         : VectorString {convId};
    if (conv.isEmpty()) {
        if (linked.owner.profileInfo.type == profile::Type::SIP) {
            auto convId = storage::beginConversationWithPeer(db,
                                                             contactUri,
                                                             true,
                                                             linked.owner.contactModel->getAddedTs(
                                                                 contactUri));
            addConversationWith(convId, contactUri, false);
            Q_EMIT linked.conversationReady(convId, contactUri);
            Q_EMIT linked.newConversation(convId);
        }
        return;
    }
    convId = conv[0];
    try {
        auto& conversation = getConversationForUid(convId).get();
        MapStringString details = ConfigurationManager::instance()
                                      .conversationInfos(linked.owner.id, conversation.uid);
        bool needsSyncing = details["syncing"] == "true";
        if (conversation.needsSyncing != needsSyncing) {
            conversation.isRequest = false;
            conversation.needsSyncing = needsSyncing;
            Q_EMIT linked.dataChanged(indexOf(conversation.uid));
            Q_EMIT linked.conversationUpdated(conversation.uid);
            invalidateModel();
            Q_EMIT linked.modelChanged();
        }
    } catch (...) {
        if (isSwarm) {
            addSwarmConversation(convId);
        }
    }
}

void
ConversationModelPimpl::addContactRequest(const QString& contactUri)
{
    try {
        getConversationForPeerUri(contactUri).get();
        // request from contact already exists, return
        return;
    } catch (std::out_of_range&) {
        // no conversation exists. Add contact request
        conversation::Info conversation(contactUri, &linked.owner);
        conversation.participants = {{contactUri, member::Role::INVITED}};
        conversation.mode = conversation::Mode::NON_SWARM;
        conversation.isRequest = true;
        emplaceBackConversation(std::move(conversation));
        invalidateModel();
        Q_EMIT linked.newConversation(contactUri);
        Q_EMIT linked.modelChanged();
    }
}

void
ConversationModelPimpl::addConversationRequest(const MapStringString& convRequest, bool emitToClient)
{
    auto convId = convRequest["id"];
    auto convIdx = indexOf(convId);
    if (convIdx != -1)
        return;

    auto peerUri = convRequest["from"];
    auto mode = conversation::to_mode(convRequest["mode"].toInt());
    QString callId, confId;
    const MapStringString& details = ConfigurationManager::instance()
                                         .conversationInfos(linked.owner.id, convId);
    conversation::Info conversation(convId, &linked.owner);
    conversation.infos = details;
    conversation.callId = callId;
    conversation.confId = confId;
    conversation.participants = {{linked.owner.profileInfo.uri, member::Role::INVITED},
                                 {peerUri, member::Role::MEMBER}};
    conversation.mode = mode;
    conversation.isRequest = true;

    MapStringString messageMap = {
        {"type", "initial"},
        {"author", peerUri},
        {"timestamp", convRequest["received"]},
        {"linearizedParent", ""},
    };
    auto msg = interaction::Info(messageMap, linked.owner.profileInfo.uri);
    conversation.interactions->insert(convId, msg);

    // add the author to the contact model's contact list as a PENDING
    // if they aren't already a contact
    auto isSelf = linked.owner.profileInfo.uri == peerUri;
    if (isSelf)
        return;

    if (mode == conversation::Mode::ONE_TO_ONE) {
        try {
            profile::Info profileInfo;
            profileInfo.uri = peerUri;
            profileInfo.type = profile::Type::JAMI;
            profileInfo.alias = details["title"];
            profileInfo.avatar = details["avatar"];
            contact::Info contactInfo;
            contactInfo.profileInfo = profileInfo;
            linked.owner.contactModel->addContact(contactInfo);
        } catch (std::out_of_range&) {
            qWarning() << "Couldn't find contact request conversation for" << peerUri;
        }
    }

    emplaceBackConversation(std::move(conversation));
    invalidateModel();
    Q_EMIT linked.newConversation(convId);
    Q_EMIT linked.modelChanged();
    if (!callId.isEmpty()) {
        // If we replace a non swarm request by a swarm request while having a call.
        linked.selectConversation(convId);
    }
    if (emitToClient)
        Q_EMIT behaviorController.newTrustRequest(linked.owner.id, convId, peerUri);
}

void
ConversationModelPimpl::slotPendingContactAccepted(const QString& uri)
{
    profile::Type type = profile::Type::INVALID;
    try {
        type = linked.owner.contactModel->getContact(uri).profileInfo.type;
    } catch (std::out_of_range& e) {
    }
    profile::Info profileInfo {uri, {}, {}, type};
    storage::createOrUpdateProfile(linked.owner.id, profileInfo, true);
    auto convs = storage::getConversationsWithPeer(db, uri);
    if (!convs.empty()) {
        try {
            auto contact = linked.owner.contactModel->getContact(uri);
            auto interaction = interaction::Info {uri,
                                                  {},
                                                  std::time(nullptr),
                                                  0,
                                                  interaction::Type::CONTACT,
                                                  interaction::Status::SUCCESS,
                                                  true};
            auto msgId = storage::addMessageToConversation(db, convs[0], interaction);
            interaction.body = storage::getContactInteractionString(uri,
                                                                    interaction::Status::SUCCESS);
            auto convIdx = indexOf(convs[0]);
            if (convIdx >= 0) {
                conversations[convIdx].interactions->append(msgId, interaction);
            }
            filteredConversations.invalidate();
            Q_EMIT linked.newInteraction(convs[0], msgId, interaction);
            Q_EMIT linked.dataChanged(convIdx);
        } catch (std::out_of_range& e) {
            qDebug() << "ConversationModelPimpl::slotContactAdded can't find contact";
        }
    }
}

void
ConversationModelPimpl::slotContactRemoved(const QString& uri)
{
    std::vector<QString> convIdsToRemove;

    // save the ids to remove from the list
    for (auto i : getIndicesForContact(uri)) {
        convIdsToRemove.emplace_back(conversations[i].uid);
    }

    // actually remove them from the list
    for (const auto& id : convIdsToRemove) {
        eraseConversation(id);
        Q_EMIT linked.conversationRemoved(id);
    }

    invalidateModel();
    Q_EMIT linked.modelChanged();
}

void
ConversationModelPimpl::slotContactModelUpdated(const QString& uri)
{
    // Update presence for all conversations with this peer
    for (auto& conversation : conversations) {
        auto members = peersForConversation(conversation);
        if (members.indexOf(uri) != -1) {
            invalidateModel();
            Q_EMIT linked.conversationUpdated(conversation.uid);
            Q_EMIT linked.dataChanged(indexOf(conversation.uid));
        }
    }

    if (currentFilter.isEmpty()) {
        if (searchResults.empty())
            return;
        searchResults.clear();
        Q_EMIT linked.searchResultUpdated();
        return;
    }
    searchResults.clear();
    auto users = linked.owner.contactModel->getSearchResults();
    for (auto& user : users) {
        auto uid = linked.owner.profileInfo.type == profile::Type::SIP ? "SEARCHSIP"
                                                                       : user.profileInfo.uri;
        conversation::Info conversationInfo(uid, &linked.owner);
        // For SIP, we always got one search result, so "" is ok as there is no empty uri
        // For Jami accounts, the nameserver can return several results, so we use the uniqueness of
        // the id as id for a temporary conversation.
        conversationInfo.participants.append(
            member::Member {user.profileInfo.uri, member::Role::MEMBER});
        searchResults.emplace_front(std::move(conversationInfo));
    }
    Q_EMIT linked.searchResultUpdated();
    Q_EMIT linked.searchResultEnded();
}

void
ConversationModelPimpl::addSwarmConversation(const QString& convId)
{
    if (Lrc::dbusIsValid()) {
        // Because the daemon may have already loaded interactions
        // we clear them to receive all signals
        ConfigurationManager::instance().clearCache(linked.owner.id, convId);
    }
    QVector<member::Member> participants;
    const VectorMapStringString& members = ConfigurationManager::instance()
                                               .getConversationMembers(linked.owner.id, convId);
    auto accountURI = linked.owner.profileInfo.uri;
    QString otherMember;
    const MapStringString& details = ConfigurationManager::instance()
                                         .conversationInfos(linked.owner.id, convId);
    auto mode = conversation::to_mode(details["mode"].toInt());
    conversation::Info conversation(convId, &linked.owner);
    conversation.infos = details;
    VectorMapStringString activeCalls = ConfigurationManager::instance()
                                            .getActiveCalls(linked.owner.id, convId);
    conversation.activeCalls = activeCalls;
    QString lastRead;
    VectorString membersLeft;
    for (auto& member : members) {
        // this check should be removed once all usage of participants replaced by
        // peersForConversation. We should have ourself in participants list
        // Note: if members.size() == 1, it's a conv with self so we're also the peer
        participants.append(member::Member {member["uri"], member::to_role(member["role"])});
        if (mode == conversation::Mode::ONE_TO_ONE && member["uri"] != accountURI) {
            otherMember = member["uri"];
        } else if (member["uri"] == accountURI) {
            lastRead = member["lastDisplayed"];
        } else if (mode != conversation::Mode::ONE_TO_ONE) {
            // Note: a conversation may be with non contacts.
            // So, refresh bestName to be sure to get quick updates in UI
            linked.owner.contactModel->bestNameForContact(member["uri"]);
        }
        if (member["uri"] != accountURI)
            conversation.interactions->setRead(member["uri"], member["lastDisplayed"]);
        if (member["role"] == "left")
            membersLeft.append(member["uri"]);
    }
    conversation.participants = participants;
    conversation.mode = mode;
    const MapStringString& preferences = ConfigurationManager::instance()
                                             .getConversationPreferences(linked.owner.id, convId);
    conversation.preferences = preferences;
    conversation.unreadMessages = ConfigurationManager::instance().countInteractions(linked.owner.id,
                                                                                     convId,
                                                                                     lastRead,
                                                                                     "",
                                                                                     accountURI);
    if (mode == conversation::Mode::ONE_TO_ONE && !otherMember.isEmpty()) {
        try {
            conversation.confId = linked.owner.callModel->getConferenceFromURI(otherMember).id;
        } catch (...) {
            conversation.confId = "";
        }
        try {
            conversation.callId = linked.owner.callModel->getCallFromURI(otherMember).id;
        } catch (...) {
            conversation.callId = "";
        }
    }
    // If conversation has only one peer it is possible that non swarm conversation was created.
    // remove non swarm conversation
    auto& peers = peersForConversation(conversation);
    if (peers.size() == 1) {
        try {
            auto& participantId = peers.front();
            auto& conv = getConversationForPeerUri(participantId).get();
            if (conv.mode == conversation::Mode::NON_SWARM) {
                eraseConversation(conv.uid);
                invalidateModel();
                Q_EMIT linked.conversationRemoved(conv.uid);
                storage::removeContactConversations(db, participantId);
            }
        } catch (...) {
        }
    }
    if (details["syncing"] == "true") {
        MapStringString messageMap = {
            {"type", "initial"},
            {"author", otherMember},
            {"timestamp", details["created"]},
            {"linearizedParent", ""},
        };
        auto msg = interaction::Info(messageMap, linked.owner.profileInfo.uri);
        conversation.interactions->append(convId, msg);
        conversation.needsSyncing = true;
        Q_EMIT linked.conversationUpdated(conversation.uid);
        Q_EMIT linked.dataChanged(indexOf(conversation.uid));
    }
    emplaceBackConversation(std::move(conversation));
    ConfigurationManager::instance().loadConversation(linked.owner.id, convId, "", 1);
}

void
ConversationModelPimpl::addConversationWith(const QString& convId,
                                            const QString& contactUri,
                                            bool isRequest)
{
    conversation::Info conversation(convId, &linked.owner);
    conversation.participants = {{contactUri, member::Role::MEMBER}};
    conversation.mode = conversation::Mode::NON_SWARM;
    conversation.needsSyncing = false;
    conversation.isRequest = isRequest;

    try {
        conversation.confId = linked.owner.callModel->getConferenceFromURI(contactUri).id;
    } catch (...) {
        conversation.confId = "";
    }
    try {
        conversation.callId = linked.owner.callModel->getCallFromURI(contactUri).id;
    } catch (...) {
        conversation.callId = "";
    }
    storage::getHistory(db, conversation, linked.owner.profileInfo.uri);

    QList<std::function<void(void)>> toUpdate;
    conversation.interactions->forEach([&](const QString& id, interaction::Info& interaction) {
        if (interaction.status != interaction::Status::SENDING) {
            return;
        }
        // Get the message status from daemon, else unknown
        auto daemonId = storage::getDaemonIdByInteractionId(db, id);
        int status = 0;
        if (daemonId.isEmpty()) {
            return;
        }
        try {
            auto msgId = std::stoull(daemonId.toStdString());
            status = ConfigurationManager::instance().getMessageStatus(msgId);
            toUpdate.emplace_back([this, convId, contactUri, daemonId, status]() {
                auto accId = linked.owner.id;
                updateInteractionStatus(accId, convId, contactUri, daemonId, status);
            });
        } catch (const std::exception& e) {
            qWarning() << Q_FUNC_INFO << "Failed: message id was invalid";
        }
    });
    Q_FOREACH (const auto& func, toUpdate)
        func();

    conversation.unreadMessages = getNumberOfUnreadMessagesFor(convId);

    emplaceBackConversation(std::move(conversation));
    invalidateModel();
}

int
ConversationModelPimpl::indexOf(const QString& uid) const
{
    for (unsigned int i = 0; i < conversations.size(); ++i) {
        if (conversations.at(i).uid == uid)
            return i;
    }
    return -1;
}

std::reference_wrapper<conversation::Info>
ConversationModelPimpl::getConversation(const FilterPredicate& pred,
                                        const bool searchResultIncluded) const
{
    auto conv = std::find_if(conversations.cbegin(), conversations.cend(), pred);
    if (conv != conversations.cend()) {
        return std::remove_const_t<conversation::Info&>(*conv);
    }

    if (searchResultIncluded) {
        auto sr = std::find_if(searchResults.cbegin(), searchResults.cend(), pred);
        if (sr != searchResults.cend()) {
            return std::remove_const_t<conversation::Info&>(*sr);
        }
    }

    throw std::out_of_range("Conversation out of range");
}

std::reference_wrapper<conversation::Info>
ConversationModelPimpl::getConversationForUid(const QString& uid,
                                              const bool searchResultIncluded) const
{
    return getConversation([uid](const conversation::Info& conv) -> bool { return uid == conv.uid; },
                           searchResultIncluded);
}

std::reference_wrapper<conversation::Info>
ConversationModelPimpl::getConversationForPeerUri(const QString& uri,
                                                  const bool searchResultIncluded) const
{
    return getConversation(
        [this, uri](const conversation::Info& conv) -> bool {
            if (!conv.isCoreDialog()) {
                return false;
            }
            auto members = peersForConversation(conv);
            if (members.isEmpty())
                return false;
            return members.indexOf(uri) != -1;
        },
        searchResultIncluded);
}

std::vector<int>
ConversationModelPimpl::getIndicesForContact(const QString& uri) const
{
    std::vector<int> ret;
    for (unsigned int i = 0; i < conversations.size(); ++i) {
        const auto& convInfo = conversations.at(i);
        if (!convInfo.isCoreDialog()) {
            continue;
        }
        auto peers = peersForConversation(convInfo);
        if (!peers.isEmpty() && peers.front() == uri) {
            ret.emplace_back(i);
        }
    }
    return ret;
}

void
ConversationModelPimpl::slotNewCall(const QString& fromId,
                                    const QString& callId,
                                    bool isOutgoing,
                                    const QString& toUri)
{
    if (isOutgoing) {
        // search contact
        currentFilter = fromId;
        invalidateModel();
        searchResults.clear();
        Q_EMIT linked.searchResultUpdated();
        linked.owner.contactModel->searchContact(currentFilter);
        Q_EMIT linked.filterChanged();
    }

    if (toUri == linked.owner.profileInfo.uri) {
        auto convIds = storage::getConversationsWithPeer(db, fromId);
        if (convIds.empty()) {
            // in case if we receive call after removing contact add conversation request;
            try {
                auto contact = linked.owner.contactModel->getContact(fromId);
                if (!isOutgoing && !contact.isBanned && fromId != linked.owner.profileInfo.uri) {
                    addContactRequest(fromId);
                }
                if (isOutgoing && contact.profileInfo.type == profile::Type::TEMPORARY) {
                    linked.owner.contactModel->addContact(contact);
                }
            } catch (const std::out_of_range&) {
            }
        }

        auto conversationIndices = getIndicesForContact(fromId);
        if (conversationIndices.empty()) {
            qDebug() << "ConversationModelPimpl::slotNewCall, but conversation not found";
            return; // Not a contact
        }

        auto& conversation = conversations.at(conversationIndices.at(0));
        qDebug() << "Add call to conversation " << conversation.uid << " - " << callId;
        conversation.callId = callId;

        addOrUpdateCallMessage(callId, fromId, true);
        Q_EMIT behaviorController.showIncomingCallView(linked.owner.id, conversation.uid);
    }
}

void
ConversationModelPimpl::slotCallStatusChanged(const QString& callId, int code)
{
    Q_UNUSED(code)
    // Get conversation
    auto i = std::find_if(conversations.begin(),
                          conversations.end(),
                          [callId](const conversation::Info& conversation) {
                              return conversation.callId == callId;
                          });

    try {
        auto call = linked.owner.callModel->getCall(callId);
        if (i != conversations.end()) {
            // Update interaction status
            invalidateModel();
            linked.selectConversation(i->uid);
            Q_EMIT linked.conversationUpdated(i->uid);
            Q_EMIT linked.dataChanged(indexOf(i->uid));
        }
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModelPimpl::slotCallStatusChanged can't get inexistant call";
    }
}

void
ConversationModelPimpl::slotCallStarted(const QString& callId)
{
    try {
        auto call = linked.owner.callModel->getCall(callId);
        addOrUpdateCallMessage(callId, call.peerUri.remove("ring:"), !call.isOutgoing);
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModelPimpl::slotCallStarted can't start inexistant call";
    }
}

void
ConversationModelPimpl::slotCallEnded(const QString& callId)
{
    try {
        auto call = linked.owner.callModel->getCall(callId);
        // get duration
        std::time_t duration = 0;
        if (call.startTime.time_since_epoch().count() != 0) {
            auto duration_ns = std::chrono::steady_clock::now() - call.startTime;
            duration = std::chrono::duration_cast<std::chrono::seconds>(duration_ns).count();
        }
        // add or update call interaction with duration
        addOrUpdateCallMessage(callId, call.peerUri.remove("ring:"), !call.isOutgoing, duration);
        /* Reset the callId stored in the conversation.
           Do not call selectConversation() since it is already done in slotCallStatusChanged. */
        for (auto& conversation : conversations)
            if (conversation.callId == callId) {
                conversation.callId = "";
                conversation.confId = ""; // The participant is detached
                invalidateModel();
                Q_EMIT linked.conversationUpdated(conversation.uid);
                Q_EMIT linked.dataChanged(indexOf(conversation.uid));
            }
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModelPimpl::slotCallEnded can't end inexistant call";
    }
}

void
ConversationModelPimpl::addOrUpdateCallMessage(const QString& callId,
                                               const QString& from,
                                               bool incoming,
                                               const std::time_t& duration)
{
    // Get conversation
    auto conv_it = std::find_if(conversations.begin(),
                                conversations.end(),
                                [&callId](const conversation::Info& conversation) {
                                    return conversation.callId == callId;
                                });
    if (conv_it == conversations.end()) {
        // If we have no conversation with peer.
        try {
            auto contact = linked.owner.contactModel->getContact(from);
            if (contact.profileInfo.type == profile::Type::PENDING) {
                addContactRequest(from);
                storage::beginConversationWithPeer(db, contact.profileInfo.uri);
            }
        } catch (const std::exception&) {
            return;
        }
        try {
            auto& conv = getConversationForPeerUri(from).get();
            if (conv.callId.isEmpty())
                conv.callId = callId;
        } catch (...) {
            return;
        }
    }
    // do not save call interaction for swarm conversation
    if (conv_it->isSwarm())
        return;
    auto uriString = incoming ? storage::prepareUri(from, linked.owner.profileInfo.type)
                              : linked.owner.profileInfo.uri;
    auto msg = interaction::Info {uriString,
                                  {},
                                  std::time(nullptr),
                                  duration,
                                  interaction::Type::CALL,
                                  interaction::Status::SUCCESS,
                                  true};
    // update the db
    auto msgId = storage::addOrUpdateMessage(db, conv_it->uid, msg, callId);
    // now set the formatted call message string in memory only
    msg.body = interaction::getCallInteractionString(msg.authorUri == linked.owner.profileInfo.uri,
                                                     msg);
    auto [added, success] = conv_it->interactions->addOrUpdate(msgId, msg);
    if (!success) {
        qWarning() << Q_FUNC_INFO << QString("Failed: to %1 msg").arg(added ? "add" : "update");
        return;
    }
    if (added)
        Q_EMIT linked.newInteraction(conv_it->uid, msgId, msg);

    invalidateModel();
    Q_EMIT linked.modelChanged();
    Q_EMIT linked.dataChanged(static_cast<int>(std::distance(conversations.begin(), conv_it)));
}

void
ConversationModelPimpl::slotNewAccountMessage(const QString& accountId,
                                              const QString& peerId,
                                              const QString& msgId,
                                              const MapStringString& payloads)
{
    if (accountId != linked.owner.id)
        return;

    for (auto it = payloads.constBegin(); it != payloads.constEnd(); ++it) {
        const auto& payload = it.key();
        if (payload.contains(TEXT_PLAIN)) {
            addIncomingMessage(peerId, it.value(), 0, msgId);
        } else {
            qDebug() << payload;
        }
    }
}

void
ConversationModelPimpl::slotIncomingCallMessage(const QString& accountId,
                                                const QString& callId,
                                                const QString& from,
                                                const QString& body)
{
    if (accountId != linked.owner.id || !linked.owner.callModel->hasCall(callId))
        return;

    auto& call = linked.owner.callModel->getCall(callId);
    if (call.type == call::Type::CONFERENCE) {
        // Show messages in all conversations for conferences.
        for (const auto& conversation : conversations) {
            if (conversation.confId == callId) {
                if (conversation.participants.empty()) {
                    continue;
                }
                addIncomingMessage(from, body);
            }
        }
    } else {
        addIncomingMessage(from, body);
    }
}

QString
ConversationModelPimpl::addIncomingMessage(const QString& peerId,
                                           const QString& body,
                                           const uint64_t& timestamp,
                                           const QString& daemonId)
{
    auto convIds = storage::getConversationsWithPeer(db, peerId);
    bool isRequest = false;
    if (convIds.empty()) {
        // in case if we receive a message after removing contact, add a conversation request
        try {
            auto contact = linked.owner.contactModel->getContact(peerId);
            isRequest = contact.profileInfo.type == profile::Type::PENDING;
            // if isSip, it will be a contact!
            auto isSip = linked.owner.profileInfo.type == profile::Type::SIP;
            if (isSip
                || (isRequest && !contact.isBanned && peerId != linked.owner.profileInfo.uri)) {
                if (!isSip)
                    addContactRequest(peerId);
                convIds.push_back(storage::beginConversationWithPeer(db, contact.profileInfo.uri));
                auto& conv = getConversationForPeerUri(contact.profileInfo.uri).get();
                conv.uid = convIds[0];
            } else {
                return "";
            }
        } catch (const std::out_of_range&) {
            return "";
        }
    }
    auto msg = interaction::Info {peerId,
                                  body,
                                  timestamp == 0 ? std::time(nullptr)
                                                 : static_cast<time_t>(timestamp),
                                  0,
                                  interaction::Type::TEXT,
                                  interaction::Status::SUCCESS,
                                  false};
    auto msgId = storage::addMessageToConversation(db, convIds[0], msg);
    if (!daemonId.isEmpty()) {
        storage::addDaemonMsgId(db, msgId, daemonId);
    }
    auto conversationIdx = indexOf(convIds[0]);
    // Add the conversation if not already here
    if (conversationIdx == -1) {
        addConversationWith(convIds[0], peerId, isRequest);
        Q_EMIT linked.newConversation(convIds[0]);
    } else {
        // Maybe check if this is failing?
        conversations[conversationIdx].interactions->append(msgId, msg);
        conversations[conversationIdx].unreadMessages = getNumberOfUnreadMessagesFor(convIds[0]);
    }

    Q_EMIT behaviorController.newUnreadInteraction(linked.owner.id, convIds[0], msgId, msg);
    Q_EMIT linked.newInteraction(convIds[0], msgId, msg);

    invalidateModel();
    Q_EMIT linked.modelChanged();
    Q_EMIT linked.dataChanged(conversationIdx);

    return msgId;
}

void
ConversationModelPimpl::slotCallAddedToConference(const QString& callId, const QString& confId)
{
    for (auto& conversation : conversations) {
        if (conversation.callId == callId && conversation.confId != confId) {
            conversation.confId = confId;
            invalidateModel();
            // Refresh the conference status only if attached
            MapStringString confDetails = CallManager::instance()
                                              .getConferenceDetails(linked.owner.id, confId);
            if (confDetails["STATE"] == "ACTIVE_ATTACHED")
                linked.selectConversation(conversation.uid);
            return;
        }
    }
}

void
ConversationModelPimpl::updateInteractionStatus(const QString& accountId,
                                                const QString& conversationId,
                                                const QString& peerUri,
                                                const QString& messageId,
                                                int status)
{
    if (accountId != linked.owner.id) {
        return;
    }
    try {
        auto& conversation = getConversationForUid(conversationId).get();
        if (conversation.isSwarm()) {
            auto emitDisplayed = false;
            using namespace libjami::Account;
            auto msgState = static_cast<MessageStates>(status);
            if (peerUri != linked.owner.profileInfo.uri) {
                auto& interactions = conversation.interactions;
                interactions->with(messageId,
                                   [&](const QString& id, const interaction::Info& interaction) {
                                       if (interaction.type == interaction::Type::TEXT) {
                                           interaction::Status newState;
                                           if (msgState == MessageStates::SENDING) {
                                               newState = interaction::Status::SENDING;
                                           } else if (msgState == MessageStates::SENT) {
                                               newState = interaction::Status::SUCCESS;
                                           } else if (msgState == MessageStates::DISPLAYED) {
                                               newState = interaction::Status::DISPLAYED;
                                           } else {
                                               return;
                                           }
                                           if (interactions->updateStatus(id, newState)
                                               && newState == interaction::Status::DISPLAYED) {
                                               emitDisplayed = true;
                                           }
                                       }
                                   });
            }

            if (emitDisplayed) {
                auto previous = conversation.interactions->getRead(peerUri);
                if (peerUri != linked.owner.profileInfo.uri)
                    conversation.interactions->setRead(peerUri, messageId);
                else {
                    // Here, this means that the daemon synced the displayed message
                    // so, compute the number of unread messages.
                    conversation.unreadMessages = ConfigurationManager::instance()
                                                      .countInteractions(linked.owner.id,
                                                                         conversationId,
                                                                         messageId,
                                                                         "",
                                                                         peerUri);
                    Q_EMIT linked.dataChanged(indexOf(conversationId));
                }
            }
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "could not update message status for not existing conversation";
    }
}

void
ConversationModelPimpl::slotConferenceRemoved(const QString& accountId, const QString& confId)
{
    if (accountId != linked.owner.id)
        return;
    // Get conversation
    for (auto& i : conversations) {
        if (i.confId == confId) {
            i.confId = "";
        }
    }
}

void
ConversationModelPimpl::slotComposingStatusChanged(const QString& accountId,
                                                   const QString& convId,
                                                   const QString& contactUri,
                                                   bool isComposing)
{
    if (accountId != linked.owner.id)
        return;

    try {
        auto& conversation = getConversationForUid(convId).get();
        if (isComposing)
            conversation.typers.insert(contactUri);
        else
            conversation.typers.remove(contactUri);
    } catch (const std::out_of_range& e) {
        qDebug() << "could not update message status for not existing conversation";
    }

    Q_EMIT linked.composingStatusChanged(convId, contactUri, isComposing);
}

int
ConversationModelPimpl::getNumberOfUnreadMessagesFor(const QString& uid)
{
    return storage::countUnreadFromInteractions(db, uid);
}

void
ConversationModel::setIsComposing(const QString& convUid, bool isComposing)
{
    try {
        auto& conversation = pimpl_->getConversationForUid(convUid).get();
        QString to = conversation.mode != conversation::Mode::NON_SWARM
                         ? "swarm:" + convUid
                         : "jami:" + pimpl_->peersForConversation(conversation).front();
        ConfigurationManager::instance().setIsComposing(owner.id, to, isComposing);
    } catch (...) {
    }
}

void
ConversationModel::sendFile(const QString& convUid,
                            const QString& path,
                            const QString& filename,
                            const QString& parent)
{
    try {
        auto& conversation = pimpl_->getConversationForUid(convUid, true).get();
        if (conversation.isSwarm()) {
            owner.dataTransferModel->sendFile(owner.id, convUid, path, filename, parent);
            return;
        }
        auto peers = pimpl_->peersForConversation(conversation);
        if (peers.size() < 1) {
            qDebug() << "send file error: could not send file in conversation with no participants";
            return;
        }
        /* isTemporary, and conversationReady callback used only for non-swarm conversation,
         because for swarm, conversation already configured at this point.
         Conversations for new contact from search result are NON_SWARM but after receiving
         conversationReady callback could be updated to ONE_TO_ONE. We still use conversationReady
         callback for one_to_one conversation to check if contact is blocked*/
        const auto peerId = peers.front();
        bool isTemporary = peerId == convUid || convUid == "SEARCHSIP";

        /* It is necessary to make a copy of convUid since it may very well point to
         a field in the temporary conversation, which is going to be destroyed by
         slotContactAdded() (indirectly triggered by sendContactrequest(). Not doing
         so may result in use after free/crash. */
        auto convUidCopy = convUid;

        pimpl_->sendContactRequest(peerId);

        auto cb = ([this, peerId, path, filename, parent](QString conversationId) {
            try {
                auto conversationOpt = getConversationForUid(conversationId);
                if (!conversationOpt.has_value()) {
                    qDebug() << "Can't send file";
                    return;
                }
                auto contactInfo = owner.contactModel->getContact(peerId);
                if (contactInfo.isBanned) {
                    qDebug() << "ContactModel::sendFile: denied, contact is banned";
                    return;
                }
                owner.dataTransferModel->sendFile(owner.id, conversationId, path, filename, parent);
            } catch (...) {
            }
        });

        if (isTemporary) {
            QMetaObject::Connection* const connection = new QMetaObject::Connection;
            *connection = connect(this,
                                  &ConversationModel::conversationReady,
                                  [cb, connection, convUidCopy](QString conversationId,
                                                                QString participantId) {
                                      if (participantId != convUidCopy) {
                                          return;
                                      }
                                      cb(conversationId);
                                      QObject::disconnect(*connection);
                                      if (connection) {
                                          delete connection;
                                      }
                                  });
        } else {
            cb(convUidCopy);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "could not send file to not existing conversation";
    }
}

void
ConversationModel::getConvMediasInfos(const QString& accountId,
                                      const QString& conversationId,
                                      const QString& text,
                                      bool isMedia)
{
    if (isMedia)
        pimpl_->mediaResearchRequestId = ConfigurationManager::instance().searchConversation(
            accountId, conversationId, "", "", text, "application/data-transfer+json", 0, 0, 0, 0);
    else
        pimpl_->msgResearchRequestId = ConfigurationManager::instance().searchConversation(
            accountId, conversationId, "", "", text, "text/plain", 0, 0, 0, 0);
}

void
ConversationModel::acceptTransfer(const QString& convUid, const QString& interactionId)
{
    lrc::api::datatransfer::Info info = {};
    getTransferInfo(convUid, interactionId, info);
    pimpl_->acceptTransfer(convUid, interactionId);
}

void
ConversationModel::cancelTransfer(const QString& convUid, const QString& fileId)
{
    // For this action, we change interaction status before effective canceling as daemon will
    // emit Finished event code immediately (before leaving this method) in non-DBus mode.
    auto conversationIdx = pimpl_->indexOf(convUid);
    bool emitUpdated = false;
    if (conversationIdx != -1) {
        auto& interactions = pimpl_->conversations[conversationIdx].interactions;
        if (interactions->updateStatus(fileId, interaction::Status::TRANSFER_CANCELED)) {
            // update information in the db
            storage::updateInteractionStatus(pimpl_->db,
                                             fileId,
                                             interaction::Status::TRANSFER_CANCELED);
            emitUpdated = true;
        }
    }
    if (emitUpdated) {
        // for swarm conversations we need to provide conversation id to accept file, for not swarm
        // conversations we need peer uri
        lrc::api::datatransfer::Info info = {};
        getTransferInfo(convUid, fileId, info);
        // Forward cancel action to daemon (will invoke slotTransferStatusCanceled)
        owner.dataTransferModel->cancel(owner.id, convUid, fileId);
        pimpl_->invalidateModel();
        Q_EMIT pimpl_->behaviorController.newReadInteraction(owner.id, convUid, fileId);
    }
}

void
ConversationModel::getTransferInfo(const QString& conversationId,
                                   const QString& interactionId,
                                   datatransfer::Info& info) const
{
    auto convOpt = getConversationForUid(conversationId);
    if (!convOpt)
        return;
    auto fileId = owner.dataTransferModel->getFileIdFromInteractionId(interactionId);
    if (convOpt->get().mode == conversation::Mode::NON_SWARM) {
        return;
    } else {
        QString path;
        qlonglong bytesProgress = 0, totalSize = 0;
        owner.dataTransferModel
            ->fileTransferInfo(owner.id, conversationId, fileId, path, totalSize, bytesProgress);
        info.path = path;
        info.totalSize = totalSize;
        info.progress = bytesProgress;
    }
}

void
ConversationModel::removeFile(const QString& conversationId,
                              const QString& interactionId,
                              const QString& path)
{
    auto convOpt = getConversationForUid(conversationId);
    if (!convOpt)
        return;

    QFile::remove(path);
    convOpt->get().interactions->updateStatus(interactionId, interaction::Status::TRANSFER_CANCELED);
}

int
ConversationModel::getNumberOfUnreadMessagesFor(const QString& convUid)
{
    return pimpl_->getNumberOfUnreadMessagesFor(convUid);
}

bool
ConversationModelPimpl::usefulDataFromDataTransfer(const QString& fileId,
                                                   const datatransfer::Info& info,
                                                   QString& interactionId,
                                                   QString& conversationId)
{
    if (info.accountId != linked.owner.id)
        return false;
    try {
        interactionId = linked.owner.dataTransferModel->getInteractionIdFromFileId(fileId);
        conversationId = info.conversationId.isEmpty()
                             ? storage::conversationIdFromInteractionId(db, interactionId)
                             : info.conversationId;
    } catch (const std::out_of_range& e) {
        qWarning() << "Couldn't get interaction from daemon Id: " << fileId;
        return false;
    }
    return true;
}

void
ConversationModelPimpl::slotTransferStatusCreated(const QString& fileId, datatransfer::Info info)
{
    // check if transfer is for the current account
    if (info.accountId != linked.owner.id)
        return;

    const MapStringString accountDetails = ConfigurationManager::instance().getAccountDetails(
        linked.owner.id);
    if (accountDetails.empty())
        return;
    // create a new conversation if needed
    auto convIds = storage::getConversationsWithPeer(db, info.peerUri);
    bool isRequest = false;
    if (convIds.empty()) {
        // in case if we receive file after removing contact add conversation request. If we have
        // swarm request this function will do nothing.
        try {
            auto contact = linked.owner.contactModel->getContact(info.peerUri);
            isRequest = contact.profileInfo.type == profile::Type::PENDING;
            if (isRequest && !contact.isBanned && info.peerUri != linked.owner.profileInfo.uri) {
                addContactRequest(info.peerUri);
                convIds.push_back(storage::beginConversationWithPeer(db, contact.profileInfo.uri));
                auto& conv = getConversationForPeerUri(contact.profileInfo.uri).get();
                conv.uid = convIds[0];
            } else {
                return;
            }
        } catch (const std::out_of_range&) {
            return;
        }
    }

    // add interaction to the db
    const auto& convId = convIds[0];
    auto interactionId = storage::addDataTransferToConversation(db, convId, info);

    // map fileId and interactionId for latter retrivial from client (that only known the interactionId)
    linked.owner.dataTransferModel->registerTransferId(fileId, interactionId);

    auto interaction = interaction::Info {info.isOutgoing ? "" : info.peerUri,
                                          info.isOutgoing ? info.path : info.displayName,
                                          std::time(nullptr),
                                          0,
                                          interaction::Type::DATA_TRANSFER,
                                          interaction::Status::TRANSFER_CREATED,
                                          false};

    // prepare interaction Info and emit signal for the client
    auto conversationIdx = indexOf(convId);
    if (conversationIdx == -1) {
        addConversationWith(convId, info.peerUri, isRequest);
        Q_EMIT linked.newConversation(convId);
    } else {
        conversations[conversationIdx].interactions->append(interactionId, interaction);
        conversations[conversationIdx].unreadMessages = getNumberOfUnreadMessagesFor(convId);
    }
    Q_EMIT behaviorController.newUnreadInteraction(linked.owner.id,
                                                   convId,
                                                   interactionId,
                                                   interaction);
    Q_EMIT linked.newInteraction(convId, interactionId, interaction);

    invalidateModel();
    Q_EMIT linked.modelChanged();
    Q_EMIT linked.dataChanged(conversationIdx);
}

void
ConversationModelPimpl::slotTransferStatusAwaitingPeer(const QString& fileId,
                                                       datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::Status::TRANSFER_AWAITING_PEER, intUpdated);
}

void
ConversationModelPimpl::slotTransferStatusAwaitingHost(const QString& fileId,
                                                       datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    awaitingHost(fileId, info);
}

bool
ConversationModelPimpl::hasOneOneSwarmWith(const QString& participant)
{
    try {
        auto& conversation = getConversationForPeerUri(participant).get();
        return conversation.mode == conversation::Mode::ONE_TO_ONE;
    } catch (std::out_of_range&) {
        return false;
    }
}

void
ConversationModelPimpl::awaitingHost(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;

    bool intUpdated;

    if (!updateTransferStatus(fileId,
                              info,
                              interaction::Status::TRANSFER_AWAITING_HOST,
                              intUpdated)) {
        return;
    }
    if (!intUpdated) {
        return;
    }
    auto conversationIdx = indexOf(conversationId);
    auto& peers = peersForConversation(conversations[conversationIdx]);
    handleIncomingFile(conversationId, interactionId, info.totalSize);
}

void
ConversationModelPimpl::handleIncomingFile(const QString& convId,
                                           const QString& interactionId,
                                           int totalSize)
{
    // If it's an accepted file type and less than 20 MB, accept transfer.
    if (linked.owner.accountModel->autoTransferFromTrusted) {
        if (linked.owner.accountModel->autoTransferSizeThreshold == 0
            || (totalSize > 0
                && static_cast<unsigned>(totalSize)
                       < linked.owner.accountModel->autoTransferSizeThreshold * 1024 * 1024)) {
            acceptTransfer(convId, interactionId);
        }
    }
}

void
ConversationModelPimpl::acceptTransfer(const QString& convUid, const QString& interactionId)
{
    auto& conversation = getConversationForUid(convUid).get();
    if (conversation.isLegacy()) // Ignore legacy
        return;

    auto& interactions = conversation.interactions;
    if (!interactions->with(interactionId, [&](const QString&, interaction::Info& interaction) {
            auto fileId = interaction.commit["fileId"];
            if (fileId.isEmpty()) {
                qWarning() << "Cannot download file without fileId";
                return;
            }
            linked.owner.dataTransferModel->download(linked.owner.id,
                                                     convUid,
                                                     interactionId,
                                                     fileId);
        })) {
        qWarning() << "Cannot download file without valid interaction";
    }
}

void
ConversationModelPimpl::invalidateModel()
{
    filteredConversations.invalidate();
    customFilteredConversations.invalidate();
}

void
ConversationModelPimpl::emplaceBackConversation(conversation::Info&& conversation)
{
    if (indexOf(conversation.uid) != -1)
        return;
    Q_EMIT linked.beginInsertRows(conversations.size());
    conversations.emplace_back(std::move(conversation));
    Q_EMIT linked.endInsertRows();
}

void
ConversationModelPimpl::eraseConversation(const QString& convId)
{
    eraseConversation(indexOf(convId));
}

void
ConversationModelPimpl::eraseConversation(int index)
{
    Q_EMIT linked.beginRemoveRows(index);
    conversations.erase(conversations.begin() + index);
    Q_EMIT linked.endRemoveRows();
}

void
ConversationModelPimpl::slotTransferStatusOngoing(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;
    bool intUpdated;

    if (!updateTransferStatus(fileId, info, interaction::Status::TRANSFER_ONGOING, intUpdated)) {
        return;
    }
    if (!intUpdated) {
        return;
    }
    auto conversationIdx = indexOf(conversationId);
    auto* timer = new QTimer();
    connect(timer, &QTimer::timeout, this, [=] {
        updateTransferProgress(timer, conversationIdx, interactionId);
    });
    timer->start(1000);
}

void
ConversationModelPimpl::slotTransferStatusFinished(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;
    // prepare interaction Info and emit signal for the client
    auto conversationIdx = indexOf(conversationId);
    if (conversationIdx != -1) {
        bool emitUpdated = false;
        auto newStatus = interaction::Status::TRANSFER_FINISHED;
        auto& interactions = conversations[conversationIdx].interactions;
        interactions->with(interactionId, [&](const QString& id, interaction::Info& interaction) {
            // We need to check if current status is ONGOING as CANCELED must not be
            // transformed into FINISHED
            if (interaction.status == interaction::Status::TRANSFER_ONGOING) {
                emitUpdated = true;
                interactions->updateStatus(id, newStatus);
            }
        });
        if (emitUpdated) {
            invalidateModel();
            if (conversations[conversationIdx].mode != conversation::Mode::NON_SWARM) {
                if (transfIdToDbIntId.find(fileId) != transfIdToDbIntId.end()) {
                    auto dbIntId = transfIdToDbIntId[fileId];
                    storage::updateInteractionStatus(db, dbIntId, newStatus);
                }
            } else {
                storage::updateInteractionStatus(db, interactionId, newStatus);
            }
            transfIdToDbIntId.remove(fileId);
        }
    }
}

void
ConversationModelPimpl::slotTransferStatusCanceled(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::Status::TRANSFER_CANCELED, intUpdated);
}

void
ConversationModelPimpl::slotTransferStatusError(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::Status::TRANSFER_ERROR, intUpdated);
}

void
ConversationModelPimpl::slotTransferStatusUnjoinable(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::Status::TRANSFER_UNJOINABLE_PEER, intUpdated);
}

void
ConversationModelPimpl::slotTransferStatusTimeoutExpired(const QString& fileId,
                                                         datatransfer::Info info)
{
    if (info.accountId != linked.owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::Status::TRANSFER_TIMEOUT_EXPIRED, intUpdated);
}

bool
ConversationModelPimpl::updateTransferStatus(const QString& fileId,
                                             datatransfer::Info info,
                                             interaction::Status newStatus,
                                             bool& updated)
{
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId)) {
        return false;
    }

    auto conversationIdx = indexOf(conversationId);
    if (conversationIdx < 0) {
        return false;
    }
    auto& conversation = conversations[conversationIdx];
    if (conversation.isLegacy()) {
        storage::updateInteractionStatus(db, interactionId, newStatus);
    }
    auto& interactions = conversations[conversationIdx].interactions;
    bool emitUpdated = interactions->updateStatus(interactionId,
                                                  newStatus,
                                                  conversation.isSwarm() ? info.path : QString());
    if (emitUpdated) {
        invalidateModel();
    }
    updated = emitUpdated;
    return true;
}

void
ConversationModelPimpl::updateTransferProgress(QTimer* timer,
                                               int conversationIdx,
                                               const QString& interactionId)
{
    try {
        bool emitUpdated = false;
        {
            const auto& interactions = conversations[conversationIdx].interactions;
            interactions->with(interactionId, [&](const QString& id, interaction::Info& interaction) {
                if (interaction.status == interaction::Status::TRANSFER_ONGOING) {
                    emitUpdated = true;
                    interactions->updateStatus(id, interaction::Status::TRANSFER_ONGOING);
                }
            });
        }
        if (emitUpdated)
            return;
    } catch (...) {
    }

    timer->stop();
    timer->deleteLater();
}

void
ConversationModelPimpl::slotConversationPreferencesUpdated(const QString&,
                                                           const QString& conversationId,
                                                           const MapStringString& preferences)
{
    auto conversationIdx = indexOf(conversationId);
    if (conversationIdx < 0)
        return;
    auto& conversation = conversations[conversationIdx];
    conversation.preferences = preferences;
    Q_EMIT linked.conversationPreferencesUpdated(conversationId);
}

} // namespace lrc

#include "api/moc_conversationmodel.cpp"
#include "conversationmodel.moc"
