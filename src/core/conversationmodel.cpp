/*
 * Copyright (C) 2017-2026 Savoir-faire Linux Inc.
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

#include "api/conversationmodel.h"
#include "conversationmodel_p.h"

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


ConversationModel::ConversationModel(const account::Info& owner,
                                     Lrc& lrc,
                                     Database& db,
                                     const CallbacksHandler& callbacksHandler,
                                     const BehaviorController& behaviorController)
    : QAbstractListModel(nullptr)
    , d_(std::make_unique<ConversationModelPrivate>(lrc, db, callbacksHandler, behaviorController))
    , owner(owner)
{
    d_->filteredConversations.bindSortCallback(this, &ConversationModel::sortConversation);
    d_->filteredConversations.bindFilterCallback(this, &ConversationModel::filterConversation);

    initConversationsImpl();

    // Contact related
    connect(&*owner.contactModel,
            &ContactModel::contactUpdated,
            this,
            &ConversationModel::slotContactUpdated);
    connect(&*owner.contactModel,
            &ContactModel::profileUpdated,
            this,
            &ConversationModel::slotContactUpdated);
    connect(&*owner.contactModel, &ContactModel::contactAdded, this, &ConversationModel::slotContactAdded);
    connect(&*owner.contactModel,
            &ContactModel::pendingContactAccepted,
            this,
            &ConversationModel::slotPendingContactAccepted);
    connect(&*owner.contactModel,
            &ContactModel::contactRemoved,
            this,
            &ConversationModel::slotContactRemoved);

    // Messages related
    connect(&*owner.contactModel,
            &lrc::ContactModel::newAccountMessage,
            this,
            &ConversationModel::slotNewAccountMessage);
    connect(&callbacksHandler,
            &CallbacksHandler::incomingCallMessage,
            this,
            &ConversationModel::slotIncomingCallMessage);
    connect(&callbacksHandler,
            &CallbacksHandler::accountMessageStatusChanged,
            this,
            &ConversationModel::updateInteractionStatus);

    // Call related
    connect(&*owner.contactModel, &ContactModel::newCall, this, &ConversationModel::slotNewCall);
    connect(&*owner.callModel,
            &lrc::api::CallModel::callStatusChanged,
            this,
            &ConversationModel::slotCallStatusChanged);
    connect(&*owner.callModel, &lrc::api::CallModel::callStarted, this, &ConversationModel::slotCallStarted);
    connect(&*owner.callModel, &lrc::api::CallModel::callEnded, this, &ConversationModel::slotCallEnded);
    connect(&*owner.callModel,
            &lrc::api::CallModel::callAddedToConference,
            this,
            &ConversationModel::slotCallAddedToConference);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::composingStatusChanged,
            this,
            &ConversationModel::slotComposingStatusChanged);
    connect(&callbacksHandler, &CallbacksHandler::needsHost, this, [&](auto accountId, auto convId) {
        if (accountId != owner.id)
            return;
        Q_EMIT needsHost(convId);
    });

    // data transfer
    connect(&*owner.contactModel,
            &ContactModel::newAccountTransfer,
            this,
            &ConversationModel::slotTransferStatusCreated);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusCanceled,
            this,
            &ConversationModel::slotTransferStatusCanceled);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusAwaitingPeer,
            this,
            &ConversationModel::slotTransferStatusAwaitingPeer);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusAwaitingHost,
            this,
            &ConversationModel::slotTransferStatusAwaitingHost);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusOngoing,
            this,
            &ConversationModel::slotTransferStatusOngoing);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusFinished,
            this,
            &ConversationModel::slotTransferStatusFinished);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusError,
            this,
            &ConversationModel::slotTransferStatusError);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusTimeoutExpired,
            this,
            &ConversationModel::slotTransferStatusTimeoutExpired);
    connect(&callbacksHandler,
            &CallbacksHandler::transferStatusUnjoinable,
            this,
            &ConversationModel::slotTransferStatusUnjoinable);
    // swarm d_->conversations
    connect(&callbacksHandler, &CallbacksHandler::swarmLoaded, this, &ConversationModel::slotSwarmLoaded);
    connect(&callbacksHandler, &CallbacksHandler::messagesFound, this, &ConversationModel::slotMessagesFound);
    connect(&callbacksHandler, &CallbacksHandler::messageReceived, this, &ConversationModel::slotMessageReceived);
    connect(&callbacksHandler, &CallbacksHandler::messageUpdated, this, &ConversationModel::slotMessageUpdated);
    connect(&callbacksHandler, &CallbacksHandler::reactionAdded, this, &ConversationModel::slotReactionAdded);
    connect(&callbacksHandler, &CallbacksHandler::reactionRemoved, this, &ConversationModel::slotReactionRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationProfileUpdated,
            this,
            &ConversationModel::slotConversationProfileUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRequestReceived,
            this,
            &ConversationModel::slotConversationRequestReceived);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRequestDeclined,
            this,
            &ConversationModel::slotConversationRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationReady,
            this,
            &ConversationModel::slotConversationReady);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationRemoved,
            this,
            &ConversationModel::slotConversationRemoved);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationMemberEvent,
            this,
            &ConversationModel::slotConversationMemberEvent);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationError,
            this,
            &ConversationModel::slotOnConversationError);
    connect(&callbacksHandler,
            &CallbacksHandler::conversationPreferencesUpdated,
            this,
            &ConversationModel::slotConversationPreferencesUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::activeCallsChanged,
            this,
            &ConversationModel::slotActiveCallsChanged);
}

void
ConversationModel::initConversations()
{
    initConversationsImpl();
}

ConversationModel::~ConversationModel() = default;

int
ConversationModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return static_cast<int>(d_->conversations.size());
}

QVariant
ConversationModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0
        || index.row() >= static_cast<int>(d_->conversations.size()))
        return {};
    return dataForItem(d_->conversations.at(index.row()), role);
}

QHash<int, QByteArray>
ConversationModel::roleNames() const
{
    using namespace ConversationList;
    QHash<int, QByteArray> roles;
    roles[Title] = "Title";
    roles[BestId] = "BestId";
    roles[Presence] = "Presence";
    roles[Alias] = "Alias";
    roles[RegisteredName] = "RegisteredName";
    roles[URI] = "URI";
    roles[BotOwner] = "BotOwner";
    roles[UnreadMessagesCount] = "UnreadMessagesCount";
    roles[LastInteractionTimeStamp] = "LastInteractionTimeStamp";
    roles[LastInteraction] = "LastInteraction";
    roles[ContactType] = "ContactType";
    roles[IsSwarm] = "IsSwarm";
    roles[IsCoreDialog] = "IsCoreDialog";
    roles[IsBanned] = "IsBanned";
    roles[UID] = "UID";
    roles[InCall] = "InCall";
    roles[IsAudioOnly] = "IsAudioOnly";
    roles[CallStackViewShouldShow] = "CallStackViewShouldShow";
    roles[CallState] = "CallState";
    roles[SectionName] = "SectionName";
    roles[AccountId] = "AccountId";
    roles[ActiveCallsCount] = "ActiveCallsCount";
    roles[Draft] = "Draft";
    roles[IsRequest] = "IsRequest";
    roles[Mode] = "Mode";
    roles[Uris] = "Uris";
    roles[Monikers] = "Monikers";
    roles[FilterTitle] = "title";
    return roles;
}

QVariant
ConversationModel::dataForItem(const conversation::Info& item, int role) const
{
    using Role = ConversationList::Role;

    switch (role) {
    case Role::InCall: {
        auto callId = item.confId.isEmpty() ? item.callId : item.confId;
        if (!callId.isEmpty() && owner.callModel->hasCall(callId))
            return true;
        return false;
    }
    case Role::IsAudioOnly: {
        auto callId = item.confId.isEmpty() ? item.callId : item.confId;
        if (!callId.isEmpty() && owner.callModel->hasCall(callId)) {
            const auto& call = owner.callModel->getCall(callId);
            return call.isAudioOnly;
        }
        return false;
    }
    case Role::CallStackViewShouldShow: {
        if (!item.callId.isEmpty() && owner.callModel->hasCall(item.callId)) {
            const auto& call = owner.callModel->getCall(item.callId);
            return ((!call.isOutgoing
                     && (call.status == call::Status::IN_PROGRESS
                         || call.status == call::Status::PAUSED
                         || call.status == call::Status::INCOMING_RINGING))
                    || (call.isOutgoing && call.status != call::Status::ENDED));
        }
        return false;
    }
    case Role::CallState: {
        auto callId = item.confId.isEmpty() ? item.callId : item.confId;
        if (!callId.isEmpty() && owner.callModel->hasCall(callId)) {
            const auto& call = owner.callModel->getCall(callId);
            return static_cast<int>(call.status);
        }
        return {};
    }
    case Role::Draft: {
        if (!item.uid.isEmpty() && draftProvider_)
            return draftProvider_(item.uid, item.accountId);
        return {};
    }
    case Role::ActiveCallsCount:
        return item.activeCalls.size();
    case Role::IsRequest:
        return item.isRequest;
    case Role::Title:
    case Role::FilterTitle:
        return title(item.uid);
    case Role::UnreadMessagesCount:
        return item.unreadMessages;
    case Role::LastInteractionTimeStamp: {
        qint32 ts = 0;
        item.interactions->withLast(
            [&ts](const QString&, const interaction::Info& interaction) {
                ts = interaction.timestamp;
            });
        return ts;
    }
    case Role::LastInteraction: {
        QString body;
        item.interactions->withLast([&](const QString&, const interaction::Info& interaction) {
            if (interaction.type == interaction::Type::UPDATE_PROFILE) {
                body = interaction::getProfileUpdatedString();
            } else if (interaction.type == interaction::Type::DATA_TRANSFER) {
                if (interaction.commit.value("tid").isEmpty())
                    body = tr("Deleted media");
                else
                    body = interaction.commit.value("displayName");
            } else if (interaction.type == interaction::Type::CALL) {
                const auto isOutgoing = interaction.authorUri == owner.profileInfo.uri;
                body = interaction::getCallInteractionString(isOutgoing, interaction);
            } else if (interaction.type == interaction::Type::CONTACT) {
                auto bestName = interaction.authorUri == owner.profileInfo.uri
                                    ? owner.accountModel->bestNameForAccount(owner.id)
                                    : owner.contactModel->bestNameForContact(interaction.authorUri);
                body = interaction::getContactInteractionString(
                    bestName,
                    interaction::to_action(interaction.commit["action"]));
            } else {
                body = interaction.body.isEmpty() ? tr("(deleted message)") : interaction.body;
            }
        });
        return body;
    }
    case Role::IsSwarm:
        return item.isSwarm();
    case Role::IsCoreDialog:
        return item.isCoreDialog();
    case Role::Mode:
        return static_cast<int>(item.mode);
    case Role::UID:
        return item.uid;
    case Role::AccountId:
        return owner.id;
    case Role::IsBanned:
        if (!item.isCoreDialog())
            return false;
        break;
    case Role::Uris:
        return peersForConversation(item.uid).toList();
    case Role::Monikers: {
        QStringList ret;
        for (const auto& peerUri : peersForConversation(item.uid)) {
            try {
                auto contact = owner.contactModel->getContact(peerUri);
                ret << contact.profileInfo.alias << contact.registeredName;
            } catch (const std::exception&) {
            }
        }
        return ret;
    }
    case Role::Presence: {
        auto maxPresence = 0;
        for (const auto& peerUri : peersForConversation(item.uid)) {
            try {
                if (peerUri == owner.profileInfo.uri)
                    return 2;
                auto contact = owner.contactModel->getContact(peerUri);
                if (contact.presence > maxPresence)
                    maxPresence = contact.presence;
            } catch (const std::exception&) {
            }
        }
        return maxPresence;
    }
    default:
        break;
    }

    // Contact-specific roles for core dialogs
    if (item.isCoreDialog()) {
        auto peerUriList = peersForConversation(item.uid);
        if (peerUriList.isEmpty())
            return {};
        auto peerUri = peerUriList.at(0);
        if (peerUri == owner.profileInfo.uri) {
            switch (role) {
            case Role::BestId:
                return owner.accountModel->bestIdForAccount(owner.id);
            case Role::Alias:
                return owner.profileInfo.alias;
            case Role::RegisteredName:
                return owner.registeredName;
            case Role::URI:
                return peerUri;
            case Role::BotOwner:
                return owner.profileInfo.botOwner;
            case Role::IsBanned:
                return false;
            case Role::ContactType:
                return static_cast<int>(owner.profileInfo.type);
            }
        }
        try {
            auto contact = owner.contactModel->getContact(peerUri);
            switch (role) {
            case Role::BestId:
                return owner.contactModel->bestIdForContact(peerUri);
            case Role::Alias:
                return contact.profileInfo.alias;
            case Role::RegisteredName:
                return contact.registeredName;
            case Role::URI:
                return peerUri;
            case Role::BotOwner:
                return contact.profileInfo.botOwner;
            case Role::IsBanned:
                return contact.isBanned;
            case Role::ContactType:
                return static_cast<int>(contact.profileInfo.type);
            }
        } catch (const std::exception&) {
        }
    }

    return {};
}

void
ConversationModel::setDraftProvider(DraftProvider provider)
{
    draftProvider_ = std::move(provider);
}

const ConversationModel::ConversationQueue&
ConversationModel::getConversations() const
{
    return d_->conversations;
}

const ConversationModel::ConversationQueueProxy&
ConversationModel::allFilteredConversations() const
{
    if (!d_->filteredConversations.isDirty())
        return d_->filteredConversations;

    return d_->filteredConversations.filter().sort().validate();
}

QMap<ConferenceableItem, ConferenceableValue>
ConversationModel::getConferenceableConversations(const QString& convId, const QString& filter) const
{
    auto conversationIt = d_->conversationMap.find(convId);
    if (conversationIt == d_->conversationMap.end() || !owner.enabled) {
        return {};
    }
    auto& conversation = d_->conversations.at(conversationIt->second);
    QMap<ConferenceableItem, ConferenceableValue> result;
    ConferenceableValue callsVector, contactsVector;

    auto& currentConfId = conversation.confId;
    auto& currentCallId = conversation.callId;
    auto calls = d_->lrc.getCalls();
    auto conferences = d_->lrc.getConferences(owner.id);
    auto& conversations = d_->conversations;
    auto currentAccountID = owner.id;
    // add contacts for current account
    for (const auto& conv : d_->conversations) {
        // d_->conversations with calls will be added in call section
        // we want to add only contacts non-swarm or one-to-one conversation
        auto& peers = peersForConversationInfo(conv);
        if (!conv.callId.isEmpty() || !conv.confId.isEmpty() || !conv.isCoreDialog() || peers.empty()) {
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

    // found d_->conversations and account for calls and conferences
    QMap<QString, QVector<AccountConversation>> tempConferences;
    for (const auto& account_id : d_->lrc.getAccountModel().getAccountList()) {
        try {
            auto& accountInfo = d_->lrc.getAccountModel().getAccountInfo(account_id);
            auto type = accountInfo.profileInfo.type == profile::Type::SIP ? FilterType::SIP : FilterType::JAMI;
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
                                           && std::find(conferences.begin(), conferences.end(), conv.confId)
                                                  != conferences.end();
                bool callFilterPredicate = !conv.callId.isEmpty() && conv.callId != currentCallId
                                           && std::find(calls.begin(), calls.end(), conv.callId) != calls.end();
                auto& peers = peersForConversationInfo(conv);
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
                bool result = (filter.isEmpty() || isConference) ? true
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
                auto& account = d_->lrc.getAccountModel().getAccountInfo(accConv.accountId);
                auto& conv = account.conversationModel->getConversationForUid(accConv.convId)->get();
                auto& peers = peersForConversationInfo(conv);
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
    return d_->searchResults;
}

const ConversationModel::ConversationQueueProxy&
ConversationModel::getFilteredConversations(const FilterType& filter, bool forceUpdate, const bool includeBanned) const
{
    if (d_->customTypeFilter == filter && !d_->customFilteredConversations.isDirty() && !forceUpdate)
        return d_->customFilteredConversations;

    d_->customTypeFilter = filter;
    return d_->customFilteredConversations.reset(d_->conversations)
        .filter([this, &includeBanned](const conversation::Info& entry) {
            try {
                if (entry.isLegacy()) {
                    auto& peers = peersForConversationInfo(entry);
                    if (peers.isEmpty()) {
                        return false;
                    }
                    auto contactInfo = owner.contactModel->getContact(peers.front());
                    // do not check blocked contacts for conversation with many participants
                    if (!includeBanned && (contactInfo.isBanned && peers.size() == 1))
                        return false;
                }
                switch (d_->customTypeFilter) {
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
    if (!d_) {
        qWarning() << "Invalid d_";
        return std::nullopt;
    }
    try {
        return std::make_optional(convForUid(uid, true));
    } catch (const std::out_of_range&) {
        return std::nullopt;
    }
}

OptRef<conversation::Info>
ConversationModel::getConversationForPeerUri(const QString& uri) const
{
    try {
        return std::make_optional(getConversation(
            [this, uri](const conversation::Info& conv) -> bool {
                if (!conv.isCoreDialog()) {
                    return false;
                }
                if (conv.mode == conversation::Mode::ONE_TO_ONE) {
                    return peersForConversationInfo(conv).indexOf(uri) != -1;
                }
                return uri == peersForConversationInfo(conv).front();
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
        return std::make_optional(
            getConversation([callId](const conversation::Info& conv)
                                        -> bool { return (callId == conv.callId || callId == conv.confId); },
                                    true));
    } catch (const std::out_of_range&) {
        return std::nullopt;
    }
}

OptRef<conversation::Info>
ConversationModel::filteredConversation(unsigned row) const
{
    auto filteredConvs = allFilteredConversations();
    if (row >= filteredConvs.get().size())
        return std::nullopt;

    return std::make_optional(filteredConvs.get().at(row));
}

OptRef<conversation::Info>
ConversationModel::searchResultForRow(unsigned row) const
{
    auto& results = d_->searchResults;
    if (row >= results.size())
        return std::nullopt;

    return std::make_optional(std::ref(results.at(row)));
}

void
ConversationModel::makePermanent(const QString& uid)
{
    try {
        auto& conversation = convForUid(uid, true).get();

        if (conversation.participants.empty()) {
            // Should not
            qDebug() << "ConversationModel::addConversation is unable to add a conversation "
                        "with no participant.";
            return;
        }

        // Send contact request if non used
        auto& peers = peersForConversationInfo(conversation);
        if (peers.size() != 1) {
            return;
        }
        sendContactRequest(peers.front());
    } catch (const std::out_of_range& e) {
        qDebug() << "Make permanent failed. Conversation not found.";
    }
}

void
ConversationModel::selectConversation(const QString& uid) const
{
    try {
        auto& conversation = convForUid(uid, true).get();

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
            CallManager::instance().resumeConference(owner.id, conversation.confId);
        }

        if (not callEnded and not conversation.confId.isEmpty()) {
            Q_EMIT d_->behaviorController.showCallView(owner.id, conversation.uid);
        } else if (callEnded) {
            Q_EMIT d_->behaviorController.showChatView(owner.id, conversation.uid);
        } else {
            try {
                auto call = owner.callModel->getCall(conversation.callId);
                switch (call.status) {
                case call::Status::INCOMING_RINGING:
                case call::Status::OUTGOING_RINGING:
                case call::Status::CONNECTING:
                case call::Status::SEARCHING:
                    // We are currently in a call
                    Q_EMIT d_->behaviorController.showIncomingCallView(owner.id, conversation.uid);
                    break;
                case call::Status::PAUSED:
                case call::Status::CONNECTED:
                case call::Status::IN_PROGRESS:
                    // We are currently receiving a call
                    Q_EMIT d_->behaviorController.showCallView(owner.id, conversation.uid);
                    break;
                case call::Status::PEER_BUSY:
                    Q_EMIT d_->behaviorController.showLeaveMessageView(owner.id, conversation.uid);
                    break;
                case call::Status::TIMEOUT:
                case call::Status::TERMINATING:
                case call::Status::INVALID:
                case call::Status::INACTIVE:
                    // call just ended
                    Q_EMIT d_->behaviorController.showChatView(owner.id, conversation.uid);
                    break;
                case call::Status::ENDED:
                default: // ENDED
                    // nothing to do
                    break;
                }
            } catch (const std::out_of_range&) {
                // Should not happen
                Q_EMIT d_->behaviorController.showChatView(owner.id, conversation.uid);
            }
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "Select conversation failed. Conversation does not exist.";
    }
}

void
ConversationModel::removeConversation(const QString& uid, bool banned, bool keepContact)
{
    // Get conversation
    auto conversationIdx = indexOf(uid);
    if (conversationIdx == -1)
        return;

    auto& conversation = d_->conversations.at(conversationIdx);
    // Remove contact from daemon
    // NOTE: this will also remove the conversation into the database for non-swarm and remove
    // conversation repository for one-to-one.
    auto& peers = peersForConversationInfo(conversation);
    if (peers.empty()) {
        // Should not
        qDebug() << "ConversationModel::removeConversation is unable to remove a conversation "
                    "without a participant.";
        return;
    }
    if (conversation.isSwarm() && !banned && (!conversation.isCoreDialog() || keepContact)) {
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

    auto currentTime = static_cast<long int>(std::time(nullptr)); // since epoch, in seconds…
    auto date = currentTime - (days * 86400);

    storage::deleteObsoleteHistory(d_->db, date);
}

void
ConversationModel::joinCall(
    const QString& uid, const QString& uri, const QString& deviceId, const QString& confId, bool videoMuted)
{
    try {
        auto& conversation = convForUid(uid, true).get();
        if (!conversation.callId.isEmpty()) {
            qWarning() << "Already in a call for swarm:" + uid;
            return;
        }
        conversation.callId = owner.callModel->createCall("rdv:" + uid + "/" + uri + "/" + deviceId + "/" + confId,
                                                          false,
                                                          {},
                                                          videoMuted);
        // Update interaction status
        invalidateModel();
        selectConversation(uid);
        Q_EMIT conversationUpdated(uid);
    } catch (...) {
    }
}

void
ConversationModel::startAudioOnlyCall(const QString& uid)
{
    startCallImpl(uid, true);
}

void
ConversationModel::startCall(const QString& uid)
{
    startCallImpl(uid);
}

MapStringString
ConversationModel::getConversationInfos(const QString& conversationId)
{
    MapStringString ret = ConfigurationManager::instance().conversationInfos(owner.id, conversationId);
    return ret;
}

MapStringString
ConversationModel::getConversationPreferences(const QString& conversationId)
{
    MapStringString ret = ConfigurationManager::instance().getConversationPreferences(owner.id, conversationId);
    return ret;
}

QString
ConversationModel::createConversation(const VectorString& participants, const MapStringString& infos)
{
    auto convUid = ConfigurationManager::instance().startConversation(owner.id);
    addSwarmConversation(convUid);
    if (!infos.isEmpty())
        updateConversationInfos(convUid, infos);
    for (const auto& participant : participants)
        ConfigurationManager::instance().addConversationMember(owner.id, convUid, participant);
    Q_EMIT newConversation(convUid);
    invalidateModel();
    Q_EMIT modelChanged();
    return convUid;
}

void
ConversationModel::updateConversationInfos(const QString& conversationId, const MapStringString infos)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;
    auto& conversation = conversationOpt->get();
    if (conversation.isCoreDialog()) {
        // If 1:1, we override a profile (as the peer will send their new profiles)
        auto peer = peersForConversationInfo(conversation);
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
    Q_EMIT conversationErrorsUpdated(conversationId);
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
ConversationModel::setConversationPreferences(const QString& conversationId, const MapStringString prefs)
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
    std::for_each(d_->conversations.begin(), d_->conversations.end(), [&pendingRequestCount](const auto& c) {
        pendingRequestCount += c.isRequest;
    });
    return pendingRequestCount;
}

int
ConversationModel::notificationsCount() const
{
    int notificationsCount = 0;
    std::for_each(d_->conversations.begin(), d_->conversations.end(), [&notificationsCount](const auto& c) {
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
ConversationModel::reloadHistory()
{
    std::for_each(d_->conversations.begin(), d_->conversations.end(), [&](const conversation::Info& c) {
        c.interactions->reloadHistory();
        Q_EMIT conversationUpdated(c.uid);
        { const auto _idx = index(indexOf(c.uid)); Q_EMIT dataChanged(_idx, _idx); }
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
        auto peer = peersForConversationInfo(conversation);
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
        auto peer = peersForConversationInfo(conversation);
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
        auto peer = peersForConversationInfo(conversation);
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
        auto& conversation = convForUid(uid, true).get();
        if (!conversation.isLegacy()) {
            ConfigurationManager::instance().sendMessage(owner.id,
                                                         uid,
                                                         body,
                                                         parentId,
                                                         static_cast<int>(MessageFlag::Text));
            return;
        }

        auto& peers = peersForConversationInfo(conversation);
        if (peers.isEmpty()) {
            // Should not
            qDebug() << "ConversationModel::sendMessage is unable to send an interaction to a "
                        "conversation with no participants.";
            return;
        }
        auto convId = uid;
        auto& peerId = peers.front();
        bool isTemporary = peerId == convId || convId == "SEARCHSIP";

        auto cb = ([this, isTemporary, body, &conversation, parentId, convId](QString conversationId) {
            if (indexOf(conversationId) < 0) {
                return;
            }
            auto& newConv = isTemporary ? convForUid(conversationId).get() : conversation;

            if (newConv.isSwarm()) {
                ConfigurationManager::instance().sendMessage(owner.id,
                                                             conversationId,
                                                             body,
                                                             parentId,
                                                             static_cast<int>(MessageFlag::Text));
                return;
            }
            auto& peers = peersForConversationInfo(newConv);
            if (peers.isEmpty()) {
                return;
            }

            uint64_t daemonMsgId = 0;
            auto status = interaction::Status::SENDING;
            auto convId = newConv.uid;

            QStringList callLists = CallManager::instance().getCallList(""); // no auto
            // workaround: sometimes, it may happen that the daemon delete a call, but d_->lrc
            // don't. We check if the call is
            //             still valid every time the user want to send a message.
            if (not newConv.callId.isEmpty() and not callLists.contains(newConv.callId))
                newConv.callId.clear();

            if (not newConv.callId.isEmpty() and call::canSendSIPMessage(owner.callModel->getCall(newConv.callId))) {
                status = interaction::Status::UNKNOWN;
                owner.callModel->sendSipMessage(newConv.callId, body);

            } else {
                daemonMsgId = owner.contactModel->sendDhtMessage(peers.front(), body);
            }

            // Add interaction to database
            interaction::Info
                msg {owner.profileInfo.uri, body, std::time(nullptr), 0, interaction::Type::TEXT, status, true};
            auto msgId = storage::addMessageToConversation(d_->db, convId, msg);

            // Update conversation
            if (status == interaction::Status::SENDING) {
                // Because the daemon already give an id for the message, we need to store it.
                storage::addDaemonMsgId(d_->db, msgId, toQString(daemonMsgId));
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
            invalidateModel();
            Q_EMIT modelChanged();
            { const auto _idx = index(indexOf(convId)); Q_EMIT dataChanged(_idx, _idx); }
        });

        if (isTemporary) {
            QMetaObject::Connection* const connection = new QMetaObject::Connection;
            *connection = connect(this,
                                  &ConversationModel::conversationReady,
                                  [cb, connection, convId](QString conversationId, QString participantId) {
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
        sendContactRequest(peerId);
        if (!isTemporary) {
            cb(convId);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "Unable to send message as conversation does not exist.";
    }
}

void
ConversationModel::editMessage(const QString& convId, const QString& newBody, const QString& messageId)
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
ConversationModel::reactMessage(const QString& convId, const QString& emoji, const QString& messageId)
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
    invalidateModel();
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
    d_->currentFilter = filter;
    invalidateModel();
    d_->searchResults.clear();
    Q_EMIT searchResultUpdated();
    owner.contactModel->searchContact(filter);
    Q_EMIT filterChanged();
}

void
ConversationModel::setFilter(const FilterType& filter)
{
    // Switch between PENDING, RING and SIP contacts.
    d_->typeFilter = filter;
    invalidateModel();
    Q_EMIT filterChanged();
}

void
ConversationModel::joinConversations(const QString& uidA, const QString& uidB)
{
    auto conversationAIdx = indexOf(uidA);
    auto conversationBIdx = indexOf(uidB);
    if (conversationAIdx == -1 || conversationBIdx == -1 || !owner.enabled)
        return;
    auto& conversationA = d_->conversations[conversationAIdx];
    auto& conversationB = d_->conversations[conversationBIdx];

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
    auto conversationIdx = indexOf(uid);
    if (conversationIdx == -1)
        return;

    auto& conversation = d_->conversations.at(conversationIdx);
    // Remove all TEXT interactions from database
    storage::clearHistory(d_->db, uid);
    // Update conversation
    conversation.interactions->clear();
    storage::getHistory(d_->db,
                        conversation,
                        owner.profileInfo.uri); // will contain "Conversation started"

    Q_EMIT modelChanged();
    Q_EMIT conversationCleared(uid);
    { const auto _idx = index(conversationIdx); Q_EMIT QAbstractListModel::dataChanged(_idx, _idx); }
}

bool
ConversationModel::isLastDisplayed(const QString& convId, const QString& interactionId, const QString participant)
{
    auto conversationIdx = indexOf(convId);
    try {
        auto& conversation = d_->conversations.at(conversationIdx);
        return conversation.interactions->getRead(participant) == interactionId;
    } catch (const std::out_of_range& e) {
    }
    return false;
}

void
ConversationModel::clearAllHistory()
{
    storage::clearAllHistory(d_->db);

    for (auto& conversation : d_->conversations) {
        {
            if (conversation.isSwarm()) {
                // WARNING: clear all history is not implemented for swarm
                continue;
            }
            conversation.interactions->clear();
        }
        storage::getHistory(d_->db, conversation, owner.profileInfo.uri);
        { const auto _idx = index(indexOf(conversation.uid)); Q_EMIT dataChanged(_idx, _idx); }
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
        conversation.interactions->withLast([&](const QString& id, interaction::Info&) { lastDisplayedId = id; });
    } else {
        conversation.interactions->forEach([&](const QString& id, interaction::Info& interaction) {
            if (interaction.isRead)
                return;
            updated = true;
            interaction.isRead = true;
            if (owner.profileInfo.type != profile::Type::SIP)
                lastDisplayedId = storage::getDaemonIdByInteractionId(d_->db, id);
            storage::setInteractionRead(d_->db, id);
        });
    }
    if (!lastDisplayedId.isEmpty()) {
        auto to = conversation.isSwarm() ? "swarm:" + convId
                                         : "jami:" + peersForConversationInfo(conversation).front();
        ConfigurationManager::instance().setMessageDisplayed(owner.id, to, lastDisplayedId, 3);
    }
    if (updated) {
        conversation.unreadMessages = 0;
        invalidateModel();
        Q_EMIT conversationUpdated(convId);
        { const auto _idx = index(indexOf(convId)); Q_EMIT dataChanged(_idx, _idx); }
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
    conversation.interactions->withLast([&lastMsgId](const QString& id, interaction::Info&) { lastMsgId = id; });
    return ConfigurationManager::instance().loadConversation(owner.id, conversationId, lastMsgId, size);
}

void
ConversationModel::acceptConversationRequest(const QString& conversationId)
{
    auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value())
        return;
    auto& conversation = conversationOpt->get();
    auto& peers = peersForConversationInfo(conversation);
    if (peers.isEmpty())
        return;

    if (conversation.isSwarm()) {
        conversation.needsSyncing = true;
        Q_EMIT conversationUpdated(conversation.uid);
        invalidateModel();
        Q_EMIT modelChanged();
        ConfigurationManager::instance().acceptConversationRequest(owner.id, conversationId);
    } else {
        sendContactRequest(peers.front());
        try {
            auto contact = owner.contactModel->getContact(peers.front());
            auto notAdded = contact.profileInfo.type == profile::Type::TEMPORARY
                            || contact.profileInfo.type == profile::Type::PENDING;
            if (notAdded) {
                contact.profileInfo.type = profile::Type::TEMPORARY;
                owner.contactModel->addContact(contact);
                return;
            }
        } catch (std::out_of_range& e) {
            qWarning() << e.what();
        }
    }
}

const VectorString
ConversationModel::peersForConversation(const QString& conversationId) const
{
    const auto conversationOpt = getConversationForUid(conversationId);
    if (!conversationOpt.has_value()) {
        return {};
    }
    const auto& conversation = conversationOpt->get();
    return peersForConversationInfo(conversation);
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

void
ConversationModel::initConversationsImpl()
{
    const MapStringString accountDetails = ConfigurationManager::instance().getAccountDetails(owner.id);
    if (accountDetails.empty())
        return;

    auto isJami = owner.profileInfo.type == profile::Type::JAMI;

    if (isJami) {
        // Fill swarm d_->conversations
        QStringList swarms = ConfigurationManager::instance().getConversations(owner.id);
        for (auto& swarmConv : swarms) {
            addSwarmConversation(swarmConv);
        }

        VectorMapStringString conversationsRequests = ConfigurationManager::instance().getConversationRequests(
            owner.id);
        for (auto& request : conversationsRequests) {
            addConversationRequest(request);
        }

        for (auto const& c : owner.contactModel->getAllContacts()) {
            if (hasOneOneSwarmWith(c))
                continue;
            bool isRequest = c.profileInfo.type == profile::Type::PENDING;
            // Can't find a conversation with this contact
            // add pending not swarm conversation
            if (isRequest) {
                addContactRequest(c.profileInfo.uri);
            }
        }
    } else {
        // Fill d_->conversations
        for (auto const& c : owner.contactModel->getAllContacts().toStdMap()) {
            auto conv = storage::getConversationsWithPeer(d_->db, c.second.profileInfo.uri);
            bool isRequest = c.second.profileInfo.type == profile::Type::PENDING;
            if (conv.empty()) {
                // Can't find a conversation with this contact
                // add pending not swarm conversation
                if (isRequest) {
                    addContactRequest(c.second.profileInfo.uri);
                    continue;
                }
                conv.push_back(storage::beginConversationWithPeer(d_->db,
                                                                  c.second.profileInfo.uri,
                                                                  true,
                                                                  owner.contactModel->getAddedTs(
                                                                      c.second.profileInfo.uri)));
            }
            addConversationWith(conv[0], c.first, isRequest);

            auto convIdx = indexOf(conv[0]);

            // Resolve any file transfer interactions were left in an incorrect state
            auto& interactions = d_->conversations[convIdx].interactions;
            interactions->forEach([&](const QString& id, interaction::Info& interaction) {
                if (interaction.transferStatus == interaction::TransferStatus::TRANSFER_CREATED
                    || interaction.transferStatus == interaction::TransferStatus::TRANSFER_AWAITING_HOST
                    || interaction.transferStatus == interaction::TransferStatus::TRANSFER_AWAITING_PEER
                    || interaction.transferStatus == interaction::TransferStatus::TRANSFER_ONGOING
                    || interaction.transferStatus == interaction::TransferStatus::TRANSFER_ACCEPTED) {
                    // If a datatransfer was left in a non-terminal status in DB, we switch this
                    // status to ERROR
                    // TODO : Improve for DBus clients as daemon and transfer may still be ongoing
                    storage::updateInteractionTransferStatus(d_->db, id, interaction::TransferStatus::TRANSFER_ERROR);

                    interaction.transferStatus = interaction::TransferStatus::TRANSFER_ERROR;
                }
            });
        }
    }
    invalidateModel();

    d_->filteredConversations.reset(d_->conversations).sort();

    // Load all non treated messages for this account
    QVector<Message> messages = ConfigurationManager::instance().getLastMessages(owner.id,
                                                                                 storage::getLastTimestamp(d_->db));
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
ConversationModel::peersForConversationInfo(const conversation::Info& conversation) const
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
        if (participant.uri != owner.profileInfo.uri)
            result.push_back(participant.uri);
    }
    return result;
}

bool
ConversationModel::filterConversation(const conversation::Info& entry)
{
    try {
        // TODO: filter for group?
        // for now group conversation filtered by first peer
        auto& peers = peersForConversationInfo(entry);
        if (peers.size() < 1) {
            return false;
        }
        auto uriPeer = peers.front();
        contact::Info contactInfo;
        try {
            contactInfo = owner.contactModel->getContact(uriPeer);
        } catch (...) {
            // Note: as we search for contacts, when importing a new account,
            // the conversation's request can be there without contact, causing
            // the function to fail.
            contactInfo.profileInfo.uri = uriPeer;
        }

        auto uri = URI(d_->currentFilter);
        bool stripScheme = (uri.schemeType() < URI::SchemeType::COUNT__);
        FlagPack<URI::Section> flags = URI::Section::USER_INFO | URI::Section::HOSTNAME | URI::Section::PORT;
        if (!stripScheme) {
            flags |= URI::Section::SCHEME;
        }

        d_->currentFilter = uri.format(flags);

        // Check contact
        // If contact is blocked, only match if filter is a perfect match
        // do not check blocked contact for conversation with multiple participants
        if (contactInfo.isBanned && peers.size() == 1) {
            if (d_->currentFilter == "")
                return false;
            return contactInfo.profileInfo.uri == d_->currentFilter || contactInfo.profileInfo.alias == d_->currentFilter
                   || contactInfo.registeredName == d_->currentFilter;
        }

        std::regex regexFilter;
        auto isValidReFilter = true;
        try {
            regexFilter = std::regex(d_->currentFilter.toStdString(), std::regex_constants::icase);
        } catch (std::regex_error&) {
            isValidReFilter = false;
        }

        auto filterUriAndReg = [regexFilter, isValidReFilter](auto contact, auto filter) {
            auto result = contact.profileInfo.uri.contains(filter) || contact.registeredName.contains(filter);
            if (!result) {
                auto regexFound = isValidReFilter
                                      ? (!contact.profileInfo.uri.isEmpty()
                                         && std::regex_search(contact.profileInfo.uri.toStdString(), regexFilter))
                                            || std::regex_search(contact.registeredName.toStdString(), regexFilter)
                                      : false;
                result |= regexFound;
            }
            return result;
        };

        // Check type
        switch (d_->typeFilter) {
        case FilterType::JAMI:
        case FilterType::SIP:
            if (entry.isRequest)
                return false;
            if (contactInfo.profileInfo.type == profile::Type::TEMPORARY)
                return filterUriAndReg(contactInfo, d_->currentFilter);
            break;
        case FilterType::REQUEST:
            if (!entry.isRequest)
                return false;
            break;
        default:
            break;
        }

        // Otherwise perform usual regex search
        bool result = contactInfo.profileInfo.alias.contains(d_->currentFilter);
        if (!result && isValidReFilter)
            result |= std::regex_search(contactInfo.profileInfo.alias.toStdString(), regexFilter);
        if (!result)
            result |= filterUriAndReg(contactInfo, d_->currentFilter);
        return result;
    } catch (std::out_of_range&) {
        // getContact() failed
        return false;
    }
}

bool
ConversationModel::sortConversation(const conversation::Info& convA, const conversation::Info& convB)
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
        auto& peersForA = peersForConversationInfo(convA);
        auto& peersForB = peersForConversationInfo(convB);
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
    historyA->withLast(
        [&](const QString&, const interaction::Info& interaction) { timestampA = interaction.timestamp; });
    historyB->withLast(
        [&](const QString&, const interaction::Info& interaction) { timestampB = interaction.timestamp; });
    return timestampA > timestampB;
}

int
ConversationModel::indexOf(const QString& uid) const
{
    auto it = d_->conversationMap.find(uid);
    if (it != d_->conversationMap.end()) {
        return it->second;
    }
    return -1;
}

std::reference_wrapper<conversation::Info>
ConversationModel::getConversation(const FilterPredicate& pred, const bool searchResultIncluded) const
{
    auto conv = std::find_if(d_->conversations.cbegin(), d_->conversations.cend(), pred);
    if (conv != d_->conversations.cend()) {
        return std::remove_const_t<conversation::Info&>(*conv);
    }

    if (searchResultIncluded) {
        auto sr = std::find_if(d_->searchResults.cbegin(), d_->searchResults.cend(), pred);
        if (sr != d_->searchResults.cend()) {
            return std::remove_const_t<conversation::Info&>(*sr);
        }
    }

    throw std::out_of_range("Conversation not found");
}

std::reference_wrapper<conversation::Info>
ConversationModel::convForUid(const QString& uid, const bool searchResultIncluded) const
{
    auto it = d_->conversationMap.find(uid);
    if (it != d_->conversationMap.end())
        return std::remove_const_t<conversation::Info&>(d_->conversations.at(it->second));
    if (searchResultIncluded) {
        auto sr = std::find_if(d_->searchResults.begin(), d_->searchResults.end(), [&](const auto& conv) {
            return conv.uid == uid;
        });
        if (sr != d_->searchResults.end()) {
            return std::remove_const_t<conversation::Info&>(*sr);
        }
    }
    throw std::out_of_range("Conversation not found");
}

std::reference_wrapper<conversation::Info>
ConversationModel::convForPeerUri(const QString& uri, const bool searchResultIncluded) const
{
    return getConversation(
        [this, uri](const conversation::Info& conv) -> bool {
            if (!conv.isCoreDialog()) {
                return false;
            }
            auto members = peersForConversationInfo(conv);
            if (members.isEmpty())
                return false;
            return members.indexOf(uri) != -1;
        },
        searchResultIncluded);
}

std::vector<int>
ConversationModel::getIndicesForContact(const QString& uri) const
{
    std::vector<int> ret;
    for (unsigned int i = 0; i < d_->conversations.size(); ++i) {
        const auto& convInfo = d_->conversations.at(i);
        if (!convInfo.isCoreDialog()) {
            continue;
        }
        auto peers = peersForConversationInfo(convInfo);
        if (!peers.isEmpty() && peers.front() == uri) {
            ret.emplace_back(i);
        }
    }
    return ret;
}

void
ConversationModel::setIsComposing(const QString& convUid, bool isComposing)
{
    try {
        auto& conversation = convForUid(convUid).get();
        QString to = conversation.mode != conversation::Mode::NON_SWARM
                         ? "swarm:" + convUid
                         : "jami:" + peersForConversationInfo(conversation).front();
        ConfigurationManager::instance().setIsComposing(owner.id, to, isComposing);
    } catch (...) {
    }
}

void
ConversationModel::sendFile(const QString& convUid, const QString& path, const QString& filename, const QString& parent)
{
    try {
        auto& conversation = convForUid(convUid, true).get();
        if (conversation.isSwarm()) {
            owner.dataTransferModel->sendFile(owner.id, convUid, path, filename, parent);
            return;
        }
        auto peers = peersForConversationInfo(conversation);
        if (peers.size() < 1) {
            qDebug() << "Send file error: unable to send file in conversation with no participants.";
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

        sendContactRequest(peerId);

        auto cb = ([this, peerId, path, filename, parent](QString conversationId) {
            try {
                auto conversationOpt = getConversationForUid(conversationId);
                if (!conversationOpt.has_value()) {
                    qDebug() << "Unable to send file.";
                    return;
                }
                auto contactInfo = owner.contactModel->getContact(peerId);
                if (contactInfo.isBanned) {
                    qDebug() << "ContactModel::sendFile: denied, contact is blocked.";
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
                                  [cb, connection, convUidCopy](QString conversationId, QString participantId) {
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
        qDebug() << "Unable to send file to conversation that does not exist.";
    }
}

void
ConversationModel::getConvMediasInfos(const QString& accountId,
                                      const QString& conversationId,
                                      const QString& text,
                                      bool isMedia)
{
    if (isMedia)
        d_->mediaResearchRequestId = ConfigurationManager::instance().searchConversation(
            accountId, conversationId, "", "", text, "application/data-transfer+json", 0, 0, 0, 0);
    else
        d_->msgResearchRequestId = ConfigurationManager::instance().searchConversation(
            accountId, conversationId, "", "", text, "text/plain", 0, 0, 0, 0);
}

void
ConversationModel::acceptTransfer(const QString& convUid, const QString& interactionId)
{
    lrc::api::datatransfer::Info info = {};
    getTransferInfo(convUid, interactionId, info);
    acceptTransferImpl(convUid, interactionId);
}

void
ConversationModel::cancelTransfer(const QString& convUid, const QString& fileId)
{
    // For this action, we change interaction status before effective canceling as daemon will
    // emit Finished event code immediately (before leaving this method) in non-DBus mode.
    auto conversationIdx = indexOf(convUid);
    bool emitUpdated = false;
    if (conversationIdx != -1) {
        auto& interactions = d_->conversations[conversationIdx].interactions;
        if (interactions->updateTransferStatus(fileId, interaction::TransferStatus::TRANSFER_CANCELED)) {
            // update information in the d_->db
            storage::updateInteractionTransferStatus(d_->db, fileId, interaction::TransferStatus::TRANSFER_CANCELED);
            emitUpdated = true;
        }
    }
    if (emitUpdated) {
        // for swarm d_->conversations we need to provide conversation id to accept file, for not swarm
        // d_->conversations we need peer uri
        lrc::api::datatransfer::Info info = {};
        getTransferInfo(convUid, fileId, info);
        // Forward cancel action to daemon (will invoke slotTransferStatusCanceled)
        owner.dataTransferModel->cancel(owner.id, convUid, fileId);
        invalidateModel();
        Q_EMIT d_->behaviorController.newReadInteraction(owner.id, convUid, fileId);
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
        owner.dataTransferModel->fileTransferInfo(owner.id, conversationId, fileId, path, totalSize, bytesProgress);
        info.path = path;
        info.totalSize = totalSize;
        info.progress = bytesProgress;
    }
}

void
ConversationModel::removeFile(const QString& conversationId, const QString& interactionId, const QString& path)
{
    auto convOpt = getConversationForUid(conversationId);
    if (!convOpt)
        return;

    QFile::remove(path);
    convOpt->get().interactions->updateTransferStatus(interactionId, interaction::TransferStatus::TRANSFER_CANCELED);
}

int
ConversationModel::getNumberOfUnreadMessagesFor(const QString& convUid)
{
    return getNumberOfUnreadMessagesForImpl(convUid);
}

void
ConversationModel::invalidateModel()
{
    d_->filteredConversations.invalidate();
    d_->customFilteredConversations.invalidate();
}

void
ConversationModel::emplaceBackConversation(conversation::Info&& conversation)
{
    if (d_->conversationMap.find(conversation.uid) != d_->conversationMap.end())
        return;
    beginInsertRows(QModelIndex(), d_->conversations.size(), d_->conversations.size());
    d_->conversations.emplace_back(std::move(conversation));
    auto newIndex = static_cast<int>(d_->conversations.size() - 1);
    auto& newConv = d_->conversations.back();
    d_->conversationMap.emplace(newConv.uid, newIndex);
    endInsertRows();
}

void
ConversationModel::eraseConversation(const QString& convId)
{
    auto it = d_->conversationMap.find(convId);
    if (it == d_->conversationMap.end())
        return;
    auto index = it->second;
    d_->conversationMap.erase(it);
    eraseConversation(index);
}

void
ConversationModel::eraseConversation(int index)
{
    if (index < 0 || index >= static_cast<int>(d_->conversations.size()))
        return;
    auto uid = d_->conversations.at(index).uid;
    d_->conversationMap.erase(uid);
    beginRemoveRows(QModelIndex(), index, index);
    d_->conversations.erase(d_->conversations.begin() + index);
    for (auto& entry : d_->conversationMap) {
        if (entry.second > index) {
            entry.second--;
        }
    }
    endRemoveRows();
}

} // namespace lrc

#include "api/moc_conversationmodel.cpp"
