/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

#include "conversationsadapter.h"

#include "utils.h"
#include "qtutils.h"
#include "systemtray.h"
#include "qmlregister.h"

#include <QApplication>

using namespace lrc::api;

ConversationsAdapter::ConversationsAdapter(SystemTray* systemTray,
                                           LRCInstance* instance,
                                           QObject* parent)
    : QmlAdapterBase(instance, parent)
    , currentTypeFilter_(profile::Type::RING)
    , systemTray_(systemTray)
    , convSrcModel_(new ConversationListModel(lrcInstance_))
    , convModel_(new ConversationListProxyModel(convSrcModel_.get()))
    , searchSrcModel_(new SearchResultsListModel(lrcInstance_))
    , searchModel_(new SelectableListProxyModel(searchSrcModel_.get()))
{
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, convModel_.get(), "ConversationListModel");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, searchModel_.get(), "SearchResultsListModel");

    new SelectableListProxyGroupModel({convModel_.data(), searchModel_.data()}, this);

    setTypeFilter(currentTypeFilter_);
    connect(this, &ConversationsAdapter::currentTypeFilterChanged, [this]() {
        setTypeFilter(currentTypeFilter_);
    });

    connect(lrcInstance_, &LRCInstance::conversationSelected, [this]() {
        auto convUid = lrcInstance_->get_selectedConvUid();
        if (!convUid.isEmpty()) {
            Q_EMIT showConversation(lrcInstance_->getCurrAccId(), convUid);
        }
    });

    updateConversationFilterData();

#ifdef Q_OS_LINUX
    // notification responses
    connect(systemTray_,
            &SystemTray::openConversationActivated,
            [this](const QString& accountId, const QString& convUid) {
                Q_EMIT lrcInstance_->notificationClicked();
                selectConversation(accountId, convUid);
                Q_EMIT lrcInstance_->updateSmartList();
            });
    connect(systemTray_,
            &SystemTray::acceptPendingActivated,
            [this](const QString& accountId, const QString& peerUri) {
                auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerUri, accountId);
                if (convInfo.uid.isEmpty())
                    return;
                lrcInstance_->getAccountInfo(accountId).conversationModel->makePermanent(
                    convInfo.uid);
            });
    connect(systemTray_,
            &SystemTray::refusePendingActivated,
            [this](const QString& accountId, const QString& peerUri) {
                auto& convInfo = lrcInstance_->getConversationFromPeerUri(peerUri, accountId);
                if (convInfo.uid.isEmpty())
                    return;
                lrcInstance_->getAccountInfo(accountId).conversationModel->removeConversation(
                    convInfo.uid);
            });
#endif
}

void
ConversationsAdapter::safeInit()
{
    conversationSmartListModel_ = new SmartListModel(this,
                                                     SmartListModel::Type::CONVERSATION,
                                                     lrcInstance_);

    Q_EMIT modelChanged(QVariant::fromValue(conversationSmartListModel_));

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showChatView,
            [this](const QString& accountId, const QString& convId) {
                // check account selection here ?
                Q_EMIT showConversation(accountId, convId);
            });

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
            &LRCInstance::currentAccountChanged,
            this,
            &ConversationsAdapter::onCurrentAccountIdChanged);

    connectConversationModel();

    setProperty("currentTypeFilter",
                QVariant::fromValue(lrcInstance_->getCurrentAccountInfo().profileInfo.type));
}

void
ConversationsAdapter::backToWelcomePage()
{
    deselectConversation();
    Q_EMIT navigateToWelcomePageRequested();
}

void
ConversationsAdapter::selectConversation(const QString& accountId, const QString& convUid)
{
    lrcInstance_->selectConversation(accountId, convUid);
}

void
ConversationsAdapter::deselectConversation()
{
    qDebug() << "ConversationsAdapter::deselectConversation";
    lrcInstance_->set_selectedConvUid();
    convModel_->deselect();
    searchModel_->deselect();
}

void
ConversationsAdapter::onCurrentAccountIdChanged()
{
    qDebug() << "ConversationsAdapter::onCurrentAccountIdChanged";
    convSrcModel_.reset(new ConversationListModel(lrcInstance_));
    convModel_->setSourceModel(convSrcModel_.get());
    searchSrcModel_.reset(new SearchResultsListModel(lrcInstance_));
    searchModel_->setSourceModel(searchSrcModel_.get());

    connectConversationModel();

    setProperty("currentTypeFilter",
                QVariant::fromValue(lrcInstance_->getCurrentAccountInfo().profileInfo.type));
}

void
ConversationsAdapter::onNewUnreadInteraction(const QString& accountId,
                                             const QString& convUid,
                                             uint64_t interactionId,
                                             const interaction::Info& interaction)
{
    if (!interaction.authorUri.isEmpty()
        && (!QApplication::focusWindow() || accountId != lrcInstance_->getCurrAccId()
            || convUid != lrcInstance_->get_selectedConvUid())) {
        auto& accountInfo = lrcInstance_->getAccountInfo(accountId);
        auto from = accountInfo.contactModel->bestNameForContact(interaction.authorUri);
#ifdef Q_OS_LINUX
        auto contactPhoto = Utils::contactPhoto(lrcInstance_,
                                                interaction.authorUri,
                                                QSize(50, 50),
                                                accountId);
        auto notifId = QString("%1;%2;%3").arg(accountId).arg(convUid).arg(interactionId);
        systemTray_->showNotification(notifId,
                                      tr("New message"),
                                      from + ": " + interaction.body,
                                      NotificationType::CHAT,
                                      Utils::QImageToByteArray(contactPhoto));

#else
        Q_UNUSED(interactionId)
        auto onClicked = [this, accountId, convUid, uri = interaction.authorUri] {
            Q_EMIT lrcInstance_->notificationClicked();
            const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
            if (!convInfo.uid.isEmpty()) {
                selectConversation(accountId, convInfo.uid);
                Q_EMIT lrcInstance_->updateSmartList();
            }
        };
        systemTray_->showNotification(interaction.body, from, onClicked);
#endif
    }
}

void
ConversationsAdapter::onNewReadInteraction(const QString& accountId,
                                           const QString& convUid,
                                           uint64_t interactionId)
{
#ifdef Q_OS_LINUX
    // hide notification
    auto notifId = QString("%1;%2;%3").arg(accountId).arg(convUid).arg(interactionId);
    systemTray_->hideNotification(notifId);
#else
    Q_UNUSED(accountId)
    Q_UNUSED(convUid)
    Q_UNUSED(interactionId)
#endif
}

void
ConversationsAdapter::onNewTrustRequest(const QString& accountId, const QString& peerUri)
{
#ifdef Q_OS_LINUX
    if (!QApplication::focusWindow() || accountId != lrcInstance_->getCurrAccId()) {
        auto& accInfo = lrcInstance_->getAccountInfo(accountId);
        auto from = accInfo.contactModel->bestNameForContact(peerUri);
        auto contactPhoto = Utils::contactPhoto(lrcInstance_, peerUri, QSize(50, 50), accountId);
        auto notifId = QString("%1;%2").arg(accountId).arg(peerUri);
        systemTray_->showNotification(notifId,
                                      tr("Trust request"),
                                      "New request from " + from,
                                      NotificationType::REQUEST,
                                      Utils::QImageToByteArray(contactPhoto));
    }
#else
    Q_UNUSED(accountId)
    Q_UNUSED(peerUri)
#endif
}

void
ConversationsAdapter::onTrustRequestTreated(const QString& accountId, const QString& peerUri)
{
#ifdef Q_OS_LINUX
    // hide notification
    auto notifId = QString("%1;%2").arg(accountId).arg(peerUri);
    systemTray_->hideNotification(notifId);
#else
    Q_UNUSED(accountId)
    Q_UNUSED(peerUri)
#endif
}

void
ConversationsAdapter::onModelChanged()
{
    conversationSmartListModel_->fillConversationsList();
    updateConversationFilterData();
}

void
ConversationsAdapter::onProfileUpdated(const QString& contactUri)
{
    conversationSmartListModel_->updateContactAvatarUid(contactUri);
    Q_EMIT updateListViewRequested();
}

void
ConversationsAdapter::onConversationUpdated(const QString& convId)
{
    updateConversationFilterData();
    // ??
    Q_EMIT updateListViewRequested();
}

void
ConversationsAdapter::onFilterChanged()
{
    conversationSmartListModel_->fillConversationsList();
    updateConversationFilterData();
    if (!lrcInstance_->get_selectedConvUid().isEmpty())
        Q_EMIT indexRepositionRequested();
    Q_EMIT updateListViewRequested();
}

void
ConversationsAdapter::onNewConversation(const QString& convUid)
{
    conversationSmartListModel_->fillConversationsList();
    updateConversationForNewContact(convUid);
}

void
ConversationsAdapter::onConversationRemoved(const QString&)
{
    backToWelcomePage();
}

void
ConversationsAdapter::onConversationCleared(const QString& convUid)
{
    // If currently selected, switch to welcome screen (deselecting
    // current smartlist item).
    if (convUid != lrcInstance_->get_selectedConvUid()) {
        return;
    }
    backToWelcomePage();
}

void
ConversationsAdapter::onSearchStatusChanged(const QString& status)
{
    Q_EMIT showSearchStatus(status);
}

void
ConversationsAdapter::onSearchResultUpdated()
{
    // currently for contact pickers
    conversationSmartListModel_->fillConversationsList();

    // smartlist search results
    searchSrcModel_->onSearchResultsUpdated();
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
        auto conversations = convModel->getFilteredConversations(profile::Type::RING, false);
        conversations.for_each([&totalUnreadMessages](const conversation::Info& conversation) {
            totalUnreadMessages += conversation.unreadMessages;
        });
    }
    set_totalUnreadMessageCount(totalUnreadMessages);
    set_pendingRequestCount(accountInfo.contactModel->pendingRequestCount());
    if (pendingRequestCount_ == 0 && currentTypeFilter_ == profile::Type::PENDING) {
        set_currentTypeFilter(profile::Type::RING);
    }
}

void
ConversationsAdapter::setFilter(const QString& filterString)
{
    convModel_->setFilter(filterString);
    searchSrcModel_->setFilter(filterString);
}

void
ConversationsAdapter::setTypeFilter(const profile::Type& typeFilter)
{
    convModel_->setTypeFilter(typeFilter);
}

bool
ConversationsAdapter::connectConversationModel(bool updateFilter)
{
    // Signal connections
    auto currentConversationModel = lrcInstance_->getCurrentConversationModel();

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::modelChanged,
                     this,
                     &ConversationsAdapter::onModelChanged,
                     Qt::UniqueConnection);

    QObject::connect(lrcInstance_->getCurrentAccountInfo().contactModel.get(),
                     &lrc::api::ContactModel::profileUpdated,
                     this,
                     &ConversationsAdapter::onProfileUpdated,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::conversationUpdated,
                     this,
                     &ConversationsAdapter::onConversationUpdated,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::filterChanged,
                     this,
                     &ConversationsAdapter::onFilterChanged,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::newConversation,
                     this,
                     &ConversationsAdapter::onNewConversation,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::conversationRemoved,
                     this,
                     &ConversationsAdapter::onConversationRemoved,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::conversationCleared,
                     this,
                     &ConversationsAdapter::onConversationCleared,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::searchStatusChanged,
                     this,
                     &ConversationsAdapter::onSearchStatusChanged,
                     Qt::UniqueConnection);

    QObject::connect(currentConversationModel,
                     &lrc::api::ConversationModel::searchResultUpdated,
                     this,
                     &ConversationsAdapter::onSearchResultUpdated,
                     Qt::UniqueConnection);

    if (updateFilter) {
        currentTypeFilter_ = lrc::api::profile::Type::INVALID;
    }
    return true;
}

void
ConversationsAdapter::updateConversationForNewContact(const QString& convUid)
{
    auto* convModel = lrcInstance_->getCurrentConversationModel();
    if (convModel == nullptr) {
        return;
    }
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid);

    if (!convInfo.uid.isEmpty() && !convInfo.participants.isEmpty()) {
        try {
            const auto contact = convModel->owner.contactModel->getContact(convInfo.participants[0]);
            if (!contact.profileInfo.uri.isEmpty()
                && contact.profileInfo.uri == lrcInstance_->get_selectedConvUid()) {
                lrcInstance_->set_selectedConvUid(convUid);
                convModel->selectConversation(convUid);
            }
        } catch (...) {
            return;
        }
    }
}
