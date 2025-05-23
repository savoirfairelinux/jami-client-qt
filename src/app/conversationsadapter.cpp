/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

#include "conversationsadapter.h"

#include "qtutils.h"
#include "systemtray.h"

#ifdef Q_OS_LINUX
#include <namedirectory.h>
#endif
#include <api/contact.h>

#include <QApplication>
#include <QJsonObject>

using namespace lrc::api;

ConversationsAdapter::ConversationsAdapter(SystemTray* systemTray,
                                           LRCInstance* instance,
                                           ConversationListProxyModel* convProxyModel,
                                           SelectableListProxyModel* searchProxyModel,
                                           QObject* parent)
    : QmlAdapterBase(instance, parent)
    , systemTray_(systemTray)
    , convSrcModel_(new ConversationListModel(lrcInstance_))
    , convModel_(convProxyModel)
    , searchSrcModel_(new SearchResultsListModel(lrcInstance_))
    , searchModel_(searchProxyModel)
{
    convModel_->bindSourceModel(convSrcModel_.get());
    searchModel_->bindSourceModel(searchSrcModel_.get());

    set_convListProxyModel(QVariant::fromValue(convModel_));
    set_searchListProxyModel(QVariant::fromValue(searchModel_));

    // this will trigger when the invite filter tab is selected
    connect(this, &ConversationsAdapter::filterRequestsChanged, [this]() {
        convModel_->setFilterRequests(filterRequests_);
    });

    connect(lrcInstance_, &LRCInstance::selectedConvUidChanged, this, [this]() {
        auto convId = lrcInstance_->get_selectedConvUid();
        if (convId.isEmpty()) {
            // deselected
            convModel_->deselect();
            searchModel_->deselect();
            Q_EMIT navigateToWelcomePageRequested();
        } else {
            // selected
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
            if (convInfo.uid.isEmpty() || convInfo.accountId != lrcInstance_->get_currentAccountId())
                return;

            auto& accInfo = lrcInstance_->getAccountInfo(convInfo.accountId);
            accInfo.conversationModel->selectConversation(convInfo.uid);
            accInfo.conversationModel->clearUnreadInteractions(convInfo.uid);

            // this may be a request, so adjust that filter also
            set_filterRequests(convInfo.isRequest);

            // reposition index in case of programmatic selection
            // currently, this may only occur for the conversation list
            // and not the search list
            convModel_->selectSourceRow(lrcInstance_->indexOf(convId));
        }
    });

    connect(lrcInstance_, &LRCInstance::draftSaved, this, [this](const QString& convId) {
        auto row = lrcInstance_->indexOf(convId);
        const auto index = convSrcModel_->index(row, 0);
        Q_EMIT convSrcModel_->dataChanged(index, index);
    });

#ifdef Q_OS_LINUX
    // notification responses
    connect(systemTray_,
            &SystemTray::openConversationActivated,
            this,
            [this](const QString& accountId, const QString& convUid) {
                Q_EMIT lrcInstance_->notificationClicked();
                lrcInstance_->selectConversation(convUid, accountId);
            });
    connect(systemTray_,
            &SystemTray::acceptPendingActivated,
            this,
            [this](const QString& accountId, const QString& convUid) {
                auto& accInfo = lrcInstance_->getAccountInfo(accountId);
                accInfo.conversationModel->acceptConversationRequest(convUid);
            });
    connect(systemTray_,
            &SystemTray::refusePendingActivated,
            this,
            [this](const QString& accountId, const QString& convUid) {
                auto& accInfo = lrcInstance_->getAccountInfo(accountId);
                accInfo.conversationModel->removeConversation(convUid);
            });
#endif

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::newUnreadInteraction,
            this,
            &ConversationsAdapter::onNewUnreadInteraction);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::newReadInteraction,
            this,
            &ConversationsAdapter::onNewReadInteraction);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::newTrustRequest,
            this,
            &ConversationsAdapter::onNewTrustRequest);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::trustRequestTreated,
            this,
            &ConversationsAdapter::onTrustRequestTreated);

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &ConversationsAdapter::onCurrentAccountIdChanged);

    connect(lrcInstance_,
            &LRCInstance::currentAccountRemoved,
            this,
            &ConversationsAdapter::onCurrentAccountRemoved,
            Qt::DirectConnection);

    connectConversationModel();
}

void
ConversationsAdapter::onCurrentAccountIdChanged()
{
    lrcInstance_->deselectConversation();

    connectConversationModel();

    // Always turn the requests filter off when switching account.
    // Conversation selection will manage the filter state in the
    // case of programmatic selection(incoming call, notification
    // activation, etc.).
    set_filterRequests(false);
}

void
ConversationsAdapter::onNewUnreadInteraction(const QString& accountId,
                                             const QString& convUid,
                                             const QString& interactionId,
                                             const interaction::Info& interaction)
{
    if (!QApplication::focusWindow() || accountId != lrcInstance_->get_currentAccountId()
        || convUid != lrcInstance_->get_selectedConvUid()) {
        auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
        if (interaction.authorUri == accountInfo.profileInfo.uri)
            return;
        auto from = accountInfo.contactModel->bestNameForContact(interaction.authorUri);
        QString displayedString;

        // Add special handling for member events
        if (interaction.type == interaction::Type::CONTACT) {
            auto action = interaction.commit.value("action");
            if (action == "join") {
                displayedString = tr("%1 has joined the conversation.").arg(from);
            } else if (action == "remove") {
                displayedString = tr("%1 has left the conversation.").arg(from);
            }
        } else if (interaction.type == interaction::Type::DATA_TRANSFER) {
            displayedString = from + ": " + interaction.commit.value("displayName");
        } else {
            displayedString = from + ": " + interaction.body;
        }

        auto preferences = accountInfo.conversationModel->getConversationPreferences(convUid);
        // Ignore notifications for this conversation
        if (preferences["ignoreNotifications"] == "true")
            return;
#ifdef Q_OS_LINUX
        auto to = lrcInstance_->accountModel().bestNameForAccount(accountId);
        auto contactPhoto = Utils::contactPhoto(lrcInstance_,
                                                interaction.authorUri,
                                                QSize(50, 50),
                                                accountId);
        auto notifId = QString("%1;%2;%3").arg(accountId, convUid, interactionId);
        systemTray_->showNotification(notifId,
                                      tr("%1 received a new message").arg(to),
                                      displayedString,
                                      SystemTray::NotificationType::CHAT,
                                      Utils::QImageToByteArray(contactPhoto));

#else
        Q_UNUSED(interactionId)
        auto onClicked = [this, accountId, convUid, uri = interaction.authorUri] {
            Q_EMIT lrcInstance_->notificationClicked();
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
            if (convInfo.uid.isEmpty())
                return;
            lrcInstance_->selectConversation(convInfo.uid, accountId);
        };
        systemTray_->showNotification(interaction.body, from, onClicked);
#endif
        updateConversationFilterData();
    }
}

void
ConversationsAdapter::onNewReadInteraction(const QString& accountId,
                                           const QString& convUid,
                                           const QString& interactionId)
{
#ifdef Q_OS_LINUX
    // hide notification
    auto notifId = QString("%1;%2;%3").arg(accountId, convUid, interactionId);
    systemTray_->hideNotification(notifId);
#else
    Q_UNUSED(accountId)
    Q_UNUSED(convUid)
    Q_UNUSED(interactionId)
#endif
}

void
ConversationsAdapter::onNewTrustRequest(const QString& accountId,
                                        const QString& convId,
                                        const QString& peerUri)
{
#ifdef Q_OS_LINUX
    if (!QApplication::focusWindow() || accountId != lrcInstance_->get_currentAccountId()) {
        auto conv = convId;
        if (conv.isEmpty()) {
            auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerUri);
            if (convInfo.uid.isEmpty())
                return;
        }
        auto to = lrcInstance_->accountModel().bestNameForAccount(accountId);

        auto cb = [this, to, accountId, conv, peerUri](QString peerBestName) {
            auto contactPhoto = Utils::contactPhoto(lrcInstance_, peerUri, QSize(50, 50), accountId);
            auto notifId = QString("%1;%2").arg(accountId, conv);
            systemTray_->showNotification(notifId,
                                          tr("%1 received a new invitation").arg(to),
                                          "New invitation from " + peerBestName,
                                          SystemTray::NotificationType::REQUEST,
                                          Utils::QImageToByteArray(contactPhoto));
        };

        // This peer is not yet a contact, so we don't have a name for it,
        // but we can attempt to look it up using the name service before
        // falling back to the bestNameForContact.
        Utils::oneShotConnect(&NameDirectory::instance(),
                              &NameDirectory::registeredNameFound,
                              this,
                              [this, accountId, peerUri, cb](NameDirectory::LookupStatus status,
                                                             const QString& address,
                                                             const QString& registeredName,
                                                             const QString& requestedName) {
                                  if (address == peerUri) {
                                      if (status == NameDirectory::LookupStatus::SUCCESS)
                                          cb(registeredName);
                                      else {
                                          auto& accInfo = lrcInstance_->getAccountInfo(accountId);
                                          cb(accInfo.contactModel->bestNameForContact(peerUri));
                                      }
                                  }
                              });
        std::ignore = NameDirectory::instance().lookupAddress(accountId, peerUri);
    }
#else
    Q_UNUSED(accountId)
    Q_UNUSED(peerUri)
#endif
    updateConversationFilterData();
}

void
ConversationsAdapter::onTrustRequestTreated(const QString& accountId, const QString& peerUri)
{
#ifdef Q_OS_LINUX
    // hide notification
    auto notifId = QString("%1;%2").arg(accountId, peerUri);
    systemTray_->hideNotification(notifId);
#else
    Q_UNUSED(accountId)
    Q_UNUSED(peerUri)
#endif
}

void
ConversationsAdapter::onModelChanged()
{
    updateConversationFilterData();
}

void
ConversationsAdapter::onProfileUpdated(const QString& contactUri)
{
    auto& convInfo = lrcInstance_->getConversationFromPeerUri(contactUri);
    if (convInfo.uid.isEmpty())
        return;

    // notify UI elements
    auto row = lrcInstance_->indexOf(convInfo.uid);
    const auto index = convSrcModel_->index(row, 0);
    Q_EMIT convSrcModel_->dataChanged(index, index);
}

void
ConversationsAdapter::onConversationUpdated(const QString& convId)
{
    updateConversationFilterData();
}

void
ConversationsAdapter::onConversationRemoved(const QString& convId)
{
    updateConversationFilterData();
}

void
ConversationsAdapter::onFilterChanged()
{
    updateConversationFilterData();
}

void
ConversationsAdapter::onConversationCleared(const QString& convUid)
{
    // If currently selected, switch to welcome screen (deselecting
    // current smartlist item).
    if (convUid == lrcInstance_->get_selectedConvUid()) {
        lrcInstance_->deselectConversation();
    }
}

void
ConversationsAdapter::onSearchStatusChanged(const QString& status)
{
    Q_EMIT showSearchStatus(status);
}

void
ConversationsAdapter::onSearchResultUpdated()
{
    // smartlist search results
    searchSrcModel_->onSearchResultsUpdated();
}

void
ConversationsAdapter::onSearchResultEnded()
{
    if (selectFirst_.exchange(false)) {
        convModel_->select(0);
        searchModel_->select(0);
    }
}

void
ConversationsAdapter::onConversationReady(const QString& convId)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
    auto selectedConvId = lrcInstance_->get_selectedConvUid();

    // for one to one conversations including legacy mode, we can prevent
    // undesired selection by filtering for a conversation peer match,
    // and for all other swarm convs, we can match the conv's id
    if (convInfo.isCoreDialog()) {
        auto peers = convModel->peersForConversation(convId);
        auto selectedPeers = convModel->peersForConversation(selectedConvId);
        if (peers != selectedPeers)
            return;
    } else if (convId != selectedConvId)
        return;

    updateConversation(convId);
}

void
ConversationsAdapter::onBannedStatusChanged(const QString& uri, bool banned)
{
    Q_UNUSED(banned)
    auto& convInfo = lrcInstance_->getConversationFromPeerUri(uri);
    if (convInfo.uid.isEmpty())
        return;
    auto row = lrcInstance_->indexOf(convInfo.uid);
    const auto index = convSrcModel_->index(row, 0);
    Q_EMIT convSrcModel_->dataChanged(index, index);
    lrcInstance_->set_selectedConvUid();
}

void
ConversationsAdapter::updateConversation(const QString& convId)
{
    // a conversation request has been accepted or a contact has
    // been added, so select the conversation and notify the UI to:
    // - switch tabs to the conversation filter tab
    // - clear search bar
    Q_EMIT conversationReady(convId);
    lrcInstance_->selectConversation(convId);
}

void
ConversationsAdapter::updateConversationFilterData()
{
    // TODO: this may be further spliced to respond separately to
    // incoming messages and invites
    // total unread message and pending invite counts, and tab selection
    auto& accountInfo = lrcInstance_->getCurrentAccountInfo();
    int totalUnreadMessages {0};
    if (accountInfo.profileInfo.type != profile::Type::SIP) {
        auto& convModel = accountInfo.conversationModel;
        auto conversations = convModel->getFilteredConversations(FilterType::JAMI, false);
        conversations.for_each([&totalUnreadMessages](const conversation::Info& conversation) {
            totalUnreadMessages += conversation.unreadMessages;
        });
    }
    set_totalUnreadMessageCount(totalUnreadMessages);
    set_pendingRequestCount(accountInfo.conversationModel->pendingRequestCount());
    systemTray_->onNotificationCountChanged(lrcInstance_->notificationsCount());

    if (get_pendingRequestCount() == 0 && get_filterRequests())
        set_filterRequests(false);
}

void
ConversationsAdapter::setFilterAndSelect(const QString& filterString)
{
    selectFirst_ = true;
    setFilter(filterString);
}

void
ConversationsAdapter::setFilter(const QString& filterString)
{
    convModel_->setFilter(filterString);
    searchSrcModel_->setFilter(filterString);
    Q_EMIT textFilterChanged(filterString);
}

void
ConversationsAdapter::ignoreFiltering(const QVariant& hightlighted)
{
    convModel_->ignoreFiltering(hightlighted.toStringList());
}

QVariantMap
ConversationsAdapter::getConvInfoMap(const QString& convId)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
    if (convInfo.participants.empty())
        return {};
    QString peerUri {};
    QString bestId {};
    const auto& accountInfo = lrcInstance_->getAccountInfo(convInfo.accountId);
    if (convInfo.isCoreDialog()) {
        try {
            peerUri = accountInfo.conversationModel->peersForConversation(convId).at(0);
            bestId = accountInfo.contactModel->bestIdForContact(peerUri);
        } catch (...) {
        }
    }

    bool isAudioOnly {false};
    if (!convInfo.uid.isEmpty()) {
        auto* call = lrcInstance_->getCallInfoForConversation(convInfo);
        if (call) {
            isAudioOnly = call->isAudioOnly;
        }
    }
    bool callStackViewShouldShow {false};
    call::Status callState {};
    if (!convInfo.callId.isEmpty()) {
        auto* callModel = lrcInstance_->getCurrentCallModel();
        const auto& call = callModel->getCall(convInfo.callId);
        callStackViewShouldShow = callModel->hasCall(convInfo.callId)
                                  && ((!call.isOutgoing
                                       && (call.status == call::Status::IN_PROGRESS
                                           || call.status == call::Status::PAUSED
                                           || call.status == call::Status::INCOMING_RINGING))
                                      || (call.isOutgoing && call.status != call::Status::ENDED));
        callState = call.status;
    }
    return {{"convId", convId},
            {"bestId", bestId},
            {"title", lrcInstance_->getCurrentConversationModel()->title(convId)},
            {"description", lrcInstance_->getCurrentConversationModel()->description(convId)},
            {"uri", peerUri},
            {"uris", accountInfo.conversationModel->peersForConversation(convId)},
            {"isSwarm", convInfo.isSwarm()},
            {"isRequest", convInfo.isRequest},
            {"needsSyncing", convInfo.needsSyncing},
            {"isAudioOnly", isAudioOnly},
            {"callState", static_cast<int>(callState)},
            {"callStackViewShouldShow", callStackViewShouldShow}};
}

void
ConversationsAdapter::restartConversation(const QString& convId)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
    if (convInfo.uid.isEmpty() || !convInfo.isCoreDialog()) {
        return;
    }

    // get the ONE_TO_ONE conv's peer uri
    auto peerUri = accInfo.conversationModel->peersForConversation(convId).at(0);

    // store a copy of the original contact so we can re-add them
    // Note: we set the profile::Type to TEMPORARY to invoke a full add
    // when calling ContactModel::addContact
    auto contactInfo = accInfo.contactModel->getContact(peerUri);
    contactInfo.profileInfo.type = profile::Type::TEMPORARY;

    Utils::oneShotConnect(
        accInfo.contactModel.get(),
        &ContactModel::contactRemoved,
        [this, &accInfo, contactInfo](const QString& peerUri) {
            // setup a callback to select another ONE_TO_ONE conversation for this peer
            // once the new conversation becomes ready
            Utils::oneShotConnect(
                accInfo.conversationModel.get(),
                &ConversationModel::conversationReady,
                [this, peerUri, &accInfo](const QString& convId) {
                    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convId);
                    // 3. filter for the correct contact-conversation and select it
                    if (!convInfo.uid.isEmpty() && convInfo.isCoreDialog()
                        && peerUri
                               == accInfo.conversationModel->peersForConversation(convId).at(0)) {
                        lrcInstance_->selectConversation(convId);
                    }
                });

            // 2. add the contact and await the conversationReady signal
            accInfo.contactModel->addContact(contactInfo);
        });

    // 1. remove the contact and await the contactRemoved signal
    accInfo.contactModel->removeContact(peerUri);
}

void
ConversationsAdapter::updateConversationTitle(const QString& convId, const QString& newTitle)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    QMap<QString, QString> details;
    details["title"] = newTitle;
    convModel->updateConversationInfos(convId, details);
}

void
ConversationsAdapter::popFrontError(const QString& convId)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    convModel->popFrontError(convId);
}

void
ConversationsAdapter::ignoreActiveCall(const QString& convId,
                                       const QString& id,
                                       const QString& uri,
                                       const QString& device)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    convModel->ignoreActiveCall(convId, id, uri, device);
}

void
ConversationsAdapter::updateConversationDescription(const QString& convId,
                                                    const QString& newDescription)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    QMap<QString, QString> details;
    details["description"] = newDescription;
    convModel->updateConversationInfos(convId, details);
}

QString
ConversationsAdapter::dialogId(const QString& peerUri)
{
    auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerUri);
    if (!convInfo.uid.isEmpty() && convInfo.isCoreDialog())
        return convInfo.uid;
    return {};
}

void
ConversationsAdapter::openDialogConversationWith(const QString& peerUri)
{
    auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerUri);
    if (convInfo.uid.isEmpty() || !convInfo.isCoreDialog())
        return;
    lrcInstance_->selectConversation(convInfo.uid);
}

void
ConversationsAdapter::onCurrentAccountRemoved()
{
    // Unbind proxy model source models if there is no current account
    if (lrcInstance_->get_currentAccountId().isEmpty()) {
        convModel_->bindSourceModel(nullptr);
        searchModel_->bindSourceModel(nullptr);
    }
}

void
ConversationsAdapter::connectConversationModel()
{
    // Signal connections
    auto model = lrcInstance_->getCurrentConversationModel();
    if (!model) {
        return;
    }

    auto connectObjectSignal = [this](auto obj, auto signal, auto slot) {
        connect(obj, signal, this, slot, Qt::UniqueConnection);
    };

    connectObjectSignal(model,
                        &ConversationModel::modelChanged,
                        &ConversationsAdapter::onModelChanged);
    connectObjectSignal(model,
                        &ConversationModel::profileUpdated,
                        &ConversationsAdapter::onProfileUpdated);
    connectObjectSignal(model,
                        &ConversationModel::conversationUpdated,
                        &ConversationsAdapter::onConversationUpdated);
    connectObjectSignal(model,
                        &ConversationModel::conversationRemoved,
                        &ConversationsAdapter::onConversationRemoved);
    connectObjectSignal(model,
                        &ConversationModel::filterChanged,
                        &ConversationsAdapter::onFilterChanged);
    connectObjectSignal(model,
                        &ConversationModel::conversationCleared,
                        &ConversationsAdapter::onConversationCleared);
    connectObjectSignal(model,
                        &ConversationModel::searchStatusChanged,
                        &ConversationsAdapter::onSearchStatusChanged);
    connectObjectSignal(model,
                        &ConversationModel::searchResultUpdated,
                        &ConversationsAdapter::onSearchResultUpdated);
    connectObjectSignal(model,
                        &ConversationModel::searchResultEnded,
                        &ConversationsAdapter::onSearchResultEnded);
    connectObjectSignal(model,
                        &ConversationModel::conversationReady,
                        &ConversationsAdapter::onConversationReady);

    connectObjectSignal(lrcInstance_->getCurrentContactModel(),
                        &ContactModel::bannedStatusChanged,
                        &ConversationsAdapter::onBannedStatusChanged);

    convSrcModel_.reset(new ConversationListModel(lrcInstance_));
    convModel_->bindSourceModel(convSrcModel_.get());
    searchSrcModel_.reset(new SearchResultsListModel(lrcInstance_));
    searchModel_->bindSourceModel(searchSrcModel_.get());

    updateConversationFilterData();
}

QString
ConversationsAdapter::createSwarm(const QString& title,
                                  const QString& description,
                                  const QString& avatar,
                                  const VectorString& participants)
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    MapStringString details;
    if (!title.isEmpty())
        details["title"] = title;
    if (!description.isEmpty())
        details["description"] = description;
    if (!avatar.isEmpty())
        details["avatar"] = avatar;
    return convModel->createConversation(participants, details);
}
