/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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

#include "lrcinstance.h"

#include "global.h"
#include "connectivitymonitor.h"

#include <QBuffer>
#include <QMutex>
#include <QObject>
#include <QPixmap>
#include <QRegularExpression>
#include <QtConcurrent/QtConcurrent>

LRCInstance::LRCInstance(const QString& updateUrl,
                         ConnectivityMonitor* connectivityMonitor,
                         bool debugMode,
                         bool muteDaemon)
    : lrc_(std::make_unique<Lrc>(!debugMode || muteDaemon))
    , updateManager_(std::make_unique<AppVersionManager>(updateUrl, connectivityMonitor, this))
    , connectivityMonitor_(*connectivityMonitor)
    , threadPool_(new QThreadPool(this))
{
    debugMode_ = debugMode;
    muteDaemon_ = muteDaemon;
    threadPool_->setMaxThreadCount(1);

    // Update the current account when the account list changes.
    connect(&accountModel(), &AccountModel::accountsReordered, this, [this] {
        Q_EMIT accountListChanged();

        profile::Info profileInfo;
        try {
            profileInfo = getCurrentAccountInfo().profileInfo;
        } catch (...) {
            return;
        }

        // update type
        set_currentAccountType(profileInfo.type);

        // notify if the avatar is stored locally
        set_currentAccountAvatarSet(!profileInfo.avatar.isEmpty());
    });

    connect(this, &LRCInstance::currentAccountIdChanged, [this] {
        // This will trigger `AccountModel::accountsReordered`.
        accountModel().setTopAccount(currentAccountId_);
    });

    connect(&accountModel(), &AccountModel::profileUpdated, this, [this](const QString& id) {
        if (id != currentAccountId_)
            return;

        auto profileInfo = getCurrentAccountInfo().profileInfo;
        set_currentAccountAvatarSet(!getCurrentAccountInfo().profileInfo.avatar.isEmpty());
    });

    connect(&accountModel(),
            &AccountModel::accountRemoved,
            this,
            &LRCInstance::onAccountRemoved,
            Qt::DirectConnection);

    // set the current account if any
    auto accountList = accountModel().getAccountList();
    if (accountList.size()) {
        set_currentAccountId(accountList.at(0));
    }
};

AppVersionManager*
LRCInstance::getAppVersionManager()
{
    return updateManager_.get();
}

void
LRCInstance::connectivityChanged()
{
    lrc_->connectivityChanged();
}

AccountModel&
LRCInstance::accountModel()
{
    return lrc_->getAccountModel();
}

BehaviorController&
LRCInstance::behaviorController()
{
    return lrc_->getBehaviorController();
}

AVModel&
LRCInstance::avModel()
{
    return lrc_->getAVModel();
}

PluginModel&
LRCInstance::pluginModel()
{
    return lrc_->getPluginModel();
}

ConnectivityMonitor&
LRCInstance::connectivityMonitor()
{
    return connectivityMonitor_;
}

bool
LRCInstance::isConnected()
{
    return lrc_->isConnected();
}

VectorString
LRCInstance::getActiveCalls(const QString& accountId)
{
    return lrc_->activeCalls(accountId);
}

int
LRCInstance::notificationsCount() const
{
    return lrc_->getAccountModel().notificationsCount();
}

const account::Info&
LRCInstance::getAccountInfo(const QString& accountId)
{
    return accountModel().getAccountInfo(accountId);
}

const account::Info&
LRCInstance::getCurrentAccountInfo()
{
    return getAccountInfo(get_currentAccountId());
}

bool
LRCInstance::hasActiveCall(bool withVideo)
{
    auto activeCalls = lrc_->activeCalls();
    auto accountList = accountModel().getAccountList();
    bool result = false;
    for (const auto& callId : activeCalls) {
        for (const auto& accountId : accountList) {
            auto& accountInfo = accountModel().getAccountInfo(accountId);
            if (withVideo) {
                if (accountInfo.callModel->hasCall(callId)) {
                    auto call = accountInfo.callModel->getCall(callId);
                    result |= !(call.isAudioOnly || call.videoMuted);
                }
            } else {
                if (accountInfo.callModel->hasCall(callId))
                    return true;
            }
        }
    }
    return result;
}

QString
LRCInstance::getCallIdForConversationUid(const QString& convUid, const QString& accountId)
{
    const auto& convInfo = getConversationFromConvUid(convUid, accountId);
    if (convInfo.uid.isEmpty()) {
        return {};
    }
    return convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;
}

const call::Info*
LRCInstance::getCallInfo(const QString& callId, const QString& accountId)
{
    try {
        auto& accInfo = accountModel().getAccountInfo(accountId);
        if (!accInfo.callModel->hasCall(callId)) {
            return nullptr;
        }
        return &accInfo.callModel->getCall(callId);
    } catch (...) {
        return nullptr;
    }
}

const call::Info*
LRCInstance::getCallInfoForConversation(const conversation::Info& convInfo, bool forceCallOnly)
{
    try {
        auto accountId = convInfo.accountId;
        auto& accInfo = accountModel().getAccountInfo(accountId);
        auto callId = forceCallOnly
                          ? convInfo.callId
                          : (convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId);
        if (!accInfo.callModel->hasCall(callId))
            return nullptr;
        return &accInfo.callModel->getCall(callId);
    } catch (...) {
        return nullptr;
    }
}

const conversation::Info&
LRCInstance::getConversationFromConvUid(const QString& convUid, const QString& accountId)
{
    auto& accInfo = accountModel().getAccountInfo(!accountId.isEmpty() ? accountId
                                                                       : get_currentAccountId());
    auto& convModel = accInfo.conversationModel;
    return convModel->getConversationForUid(convUid).value_or(invalid);
}

const conversation::Info&
LRCInstance::getConversationFromPeerUri(const QString& peerUri, const QString& accountId)
{
    auto& accInfo = accountModel().getAccountInfo(!accountId.isEmpty() ? accountId
                                                                       : get_currentAccountId());
    auto& convModel = accInfo.conversationModel;
    return convModel->getConversationForPeerUri(peerUri).value_or(invalid);
}

const conversation::Info&
LRCInstance::getConversationFromCallId(const QString& callId, const QString& accountId)
{
    auto& accInfo = accountModel().getAccountInfo(!accountId.isEmpty() ? accountId
                                                                       : get_currentAccountId());
    auto& convModel = accInfo.conversationModel;
    return convModel->getConversationForCallId(callId).value_or(invalid);
}

ConversationModel*
LRCInstance::getCurrentConversationModel()
{
    try {
        const auto& accInfo = getCurrentAccountInfo();
        return accInfo.conversationModel.get();
    } catch (...) {
        return nullptr;
    }
}

CallModel*
LRCInstance::getCurrentCallModel()
{
    try {
        const auto& accInfo = getCurrentAccountInfo();
        return accInfo.callModel.get();
    } catch (...) {
        return nullptr;
    }
}

ContactModel*
LRCInstance::getCurrentContactModel()
{
    try {
        const auto& accInfo = getCurrentAccountInfo();
        return accInfo.contactModel.get();
    } catch (...) {
        return nullptr;
    }
}

int
LRCInstance::getCurrentAccountIndex()
{
    for (int i = 0; i < accountModel().getAccountCount(); i++) {
        if (accountModel().getAccountList()[i] == get_currentAccountId()) {
            return i;
        }
    }
    return -1;
}

void
LRCInstance::setCurrAccDisplayName(const QString& displayName)
{
    auto accountId = get_currentAccountId();
    accountModel().setAlias(accountId, displayName);
    /*
     * Force save to .yml.
     */
    auto confProps = accountModel().getAccountConfig(accountId);
    accountModel().setAccountConfig(accountId, confProps);
}

const account::ConfProperties_t&
LRCInstance::getCurrAccConfig()
{
    return getCurrentAccountInfo().confProperties;
}

int
LRCInstance::indexOf(const QString& convId)
{
    auto& convs = getCurrentConversationModel()->getConversations();
    auto it = std::find_if(convs.begin(),
                           convs.end(),
                           [convId](const lrc::api::conversation::Info& conv) {
                               return conv.uid == convId;
                           });
    return it != convs.end() ? std::distance(convs.begin(), it) : -1;
}

void
LRCInstance::subscribeToDebugReceived()
{
    lrc_->subscribeToDebugReceived();
}

void
LRCInstance::startAudioMeter()
{
    threadPool_->start([this] {
        if (!getActiveCalls().size()) {
            avModel().startAudioDevice();
        }
        avModel().setAudioMeterState(true);
    });
}

void
LRCInstance::stopAudioMeter()
{
    threadPool_->start([this] {
        if (!getActiveCalls().size()) {
            avModel().stopAudioDevice();
        }
        avModel().setAudioMeterState(false);
    });
}

QVariantMap
LRCInstance::getContentDraft(const QString& convUid, const QString& accountId)
{
    auto draftKey = accountId + "_" + convUid;
    QVariantMap draftMap;
    draftMap["text"] = contentDrafts_[draftKey];
    draftMap["files"] = fileDrafts_[draftKey];

    return draftMap;
}

void
LRCInstance::setContentDraft(const QString& convUid,
                             const QString& accountId,
                             const QString& textDraft,
                             const QList<QString>& filePathDraft)
{
    if (accountId.isEmpty() || convUid.isEmpty()) {
        return;
    }
    auto draftKey = accountId + "_" + convUid;

    // prevent a senseless dataChanged signal from the
    // model if nothing has changed
    if (contentDrafts_[draftKey] == textDraft && fileDrafts_[draftKey] == filePathDraft) {
        return;
    }

    contentDrafts_[draftKey] = textDraft;
    fileDrafts_[draftKey] = filePathDraft;
    // this signal is only needed to update the current smartlist
    Q_EMIT draftSaved(convUid);
}

void
LRCInstance::selectConversation(const QString& convId, const QString& accountId)
{
    // reselection can be used to update the conversation
    if (convId == selectedConvUid_ && accountId == currentAccountId_) {
        Q_EMIT conversationUpdated(convId, accountId);
        return;
    }

    // if the account is not currently selected, do that first, then
    // proceed to select the conversation
    if (!accountId.isEmpty() && accountId != get_currentAccountId()) {
        Utils::oneShotConnect(this, &LRCInstance::currentAccountIdChanged, [this, convId] {
            set_selectedConvUid(convId);
        });
        set_currentAccountId(accountId);
        return;
    }
    set_selectedConvUid(convId);
}

int
LRCInstance::indexOfActiveCall(const QString& confId, const QString& uri, const QString& deviceId)
{
    if (auto optConv = getCurrentConversationModel()->getConversationForUid(selectedConvUid_)) {
        auto& convInfo = optConv->get();
        return convInfo.indexOfActiveCall(confId, uri, deviceId);
    }
    return -1;
}

void
LRCInstance::deselectConversation()
{
    // Only do this if we have an account selected
    if (get_currentAccountId().isEmpty()) {
        return;
    }
    set_selectedConvUid();
}

void
LRCInstance::makeConversationPermanent(const QString& convId, const QString& accountId)
{
    auto aId = accountId.isEmpty() ? currentAccountId_ : accountId;
    const auto& accInfo = accountModel().getAccountInfo(aId);
    auto cId = convId.isEmpty() ? selectedConvUid_ : convId;
    if (cId.isEmpty()) {
        qInfo() << Q_FUNC_INFO << "no conversation to make permanent";
        return;
    }
    accInfo.conversationModel.get()->makePermanent(cId);
}

void
LRCInstance::finish()
{
    lrc_.reset();
}

void
LRCInstance::monitor(bool continuous)
{
    lrc_->monitor(continuous);
}

QString
LRCInstance::getCurrentCallId(bool forceCallOnly)
{
    try {
        const auto& convInfo = getConversationFromConvUid(get_selectedConvUid());
        auto call = getCallInfoForConversation(convInfo, forceCallOnly);
        return call ? call->id : QString();
    } catch (...) {
        return QString();
    }
}

QString
LRCInstance::get_selectedConvUid()
{
    return selectedConvUid_;
}

void
LRCInstance::set_selectedConvUid(QString selectedConvUid)
{
    if (selectedConvUid_ != selectedConvUid) {
        selectedConvUid_ = selectedConvUid;
        Q_EMIT selectedConvUidChanged();
    }
}

VectorMapStringString
LRCInstance::getConnectionList(const QString& accountId, const QString& uid)
{
    return Lrc::getConnectionList(accountId, uid);
}

VectorMapStringString
LRCInstance::getChannelList(const QString& accountId, const QString& uid)
{
    return Lrc::getChannelList(accountId, uid);
}

void
LRCInstance::onAccountRemoved(const QString& accountId)
{
    if (accountId != currentAccountId_)
        return;

    // If there are any accounts left, select the first one, otherwise clear the current account
    // and request presentation of the wizard view.
    auto accountList = accountModel().getAccountList();
    if (accountList.size()) {
        set_currentAccountId(accountList.at(0));
    } else {
        set_currentAccountId();
    }

    Q_EMIT currentAccountRemoved();
}
