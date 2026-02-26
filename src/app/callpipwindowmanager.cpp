/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include "callpipwindowmanager.h"
#include "lrcinstance.h"

#include <api/call.h>
#include <api/callmodel.h>
#include <api/conversationmodel.h>

#include <QApplication>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>

CallPipWindowManager::CallPipWindowManager(QQmlEngine* engine,
                                           LRCInstance* lrcInstance,
                                           QObject* parent)
    : QObject(parent)
    , engine_(engine)
    , lrcInstance_(lrcInstance)
{
    prevSelectedConvId_ = lrcInstance_->get_selectedConvUid();

    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &CallPipWindowManager::onSelectedConvChanged);

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &CallPipWindowManager::onAccountChanged);
}

CallPipWindowManager*
CallPipWindowManager::create(QQmlEngine* engine, QJSEngine*)
{
    auto* lrcInstance = qApp->property("LRCInstance").value<LRCInstance*>();
    return new CallPipWindowManager(engine, lrcInstance);
}

QString
CallPipWindowManager::pipPreviewId() const
{
    if (pipCallId_.isEmpty() || pipAccountId_.isEmpty())
        return {};
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(pipAccountId_);
        if (accInfo.callModel->hasCall(pipCallId_)) {
            auto callInfo = accInfo.callModel->getCall(pipCallId_);
            return callInfo.getCallInfoEx()[QStringLiteral("preview_id")].toString();
        }
    } catch (...) {
    }
    return {};
}

void
CallPipWindowManager::popOutCall(const QString& convId, const QString& accountId)
{
    // If this call is already in PiP, just raise the window.
    if (pipConvId_ == convId && !window_.isNull()) {
        window_->raise();
        window_->requestActivate();
        return;
    }

    // Close any existing PiP window before opening a new one.
    closePip();

    // Retrieve the active call ID for this conversation.
    const QString callId = lrcInstance_->getCallIdForConversationUid(convId, accountId);
    if (callId.isEmpty()) {
        qWarning() << "CallPipWindowManager: no active call for conv" << convId;
        return;
    }

    // Instantiate CallPipWindow.qml.
    QQmlComponent component(engine_, QUrl(QStringLiteral("qrc:/CallPipWindow.qml")));
    if (component.status() != QQmlComponent::Ready) {
        qWarning() << "CallPipWindowManager: component error:" << component.errorString();
        return;
    }

    auto* rootObj = component.createWithInitialProperties(
        {{"pipConvId", convId}, {"pipAccountId", accountId}});
    if (!rootObj) {
        qWarning() << "CallPipWindowManager: failed to create PiP window";
        return;
    }

    QQmlEngine::setObjectOwnership(rootObj, QQmlEngine::CppOwnership);
    auto* win = qobject_cast<QQuickWindow*>(rootObj);
    if (!win) {
        qWarning() << "CallPipWindowManager: root object is not a QQuickWindow";
        rootObj->deleteLater();
        return;
    }

    window_ = QPointer<QQuickWindow>(win);
    pipConvId_ = convId;
    pipAccountId_ = accountId;
    pipCallId_ = callId;

    // Clean up when the window is closed.
    connect(win, &QQuickWindow::closing, this, [this, win](QQuickCloseEvent*) {
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        disconnectCallModel();
        win->deleteLater();
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
    });

    // Monitor call status to auto-close the PiP when the call ends.
    connectCallModel(accountId);

    win->show();
    Q_EMIT isPipActiveChanged();
    Q_EMIT pipConvIdChanged();
    Q_EMIT pipCallIdChanged();
    Q_EMIT pipAccountIdChanged();
    Q_EMIT pipPreviewIdChanged();
}

void
CallPipWindowManager::reabsorb()
{
    if (pipConvId_.isEmpty())
        return;

    const QString convId = pipConvId_;
    const QString accountId = pipAccountId_;

    // Close PiP window first (will clear pipConvId_ etc. via closing signal).
    closePip();

    // Select the call conversation in the main window.
    lrcInstance_->selectConversation(convId, accountId);
}

void
CallPipWindowManager::closeAll()
{
    closePip();
}

void
CallPipWindowManager::closeForAccount(const QString& accountId)
{
    if (pipAccountId_ == accountId)
        closePip();
}

void
CallPipWindowManager::onSelectedConvChanged()
{
    const QString newConvId = lrcInstance_->get_selectedConvUid();

    // Only act if the user actually switched to a different conversation.
    if (!prevSelectedConvId_.isEmpty() && prevSelectedConvId_ != newConvId) {
        // Check whether the conversation we just navigated away from has an active call.
        const QString accountId = lrcInstance_->get_currentAccountId();
        const QString callId = lrcInstance_->getCallIdForConversationUid(prevSelectedConvId_, accountId);
        if (!callId.isEmpty()) {
            // Don't pop out if a PiP window is already showing this call.
            if (pipConvId_ != prevSelectedConvId_) {
                popOutCall(prevSelectedConvId_, accountId);
            }
        }
    }

    // If the user navigates back to the conversation that is in PiP, reabsorb it.
    if (!newConvId.isEmpty() && newConvId == pipConvId_) {
        closePip();
    }

    prevSelectedConvId_ = newConvId;
}

void
CallPipWindowManager::onCallStatusChanged(const QString& accountId, const QString& callId, int code)
{
    Q_UNUSED(code)
    if (callId != pipCallId_)
        return;

    // Read the actual call status from the model (code is a raw SIP reason
    // code, not a call::Status enum value).
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (!accInfo.callModel->hasCall(callId)) {
            // Call already removed from model — treat as ended.
            closePip();
            return;
        }
        const auto status = accInfo.callModel->getCall(callId).status;
        if (status == lrc::api::call::Status::ENDED || status == lrc::api::call::Status::TERMINATING
            || status == lrc::api::call::Status::TIMEOUT
            || status == lrc::api::call::Status::PEER_BUSY) {
            closePip();
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::onCallStatusChanged:" << e.what();
        closePip();
    }
}

void
CallPipWindowManager::onAccountChanged()
{
    // Close PiP if the active account changes — the call belongs to the old account.
    if (!pipAccountId_.isEmpty() && pipAccountId_ != lrcInstance_->get_currentAccountId()) {
        closePip();
    }
}

void
CallPipWindowManager::closePip()
{
    disconnectCallModel();
    if (!window_.isNull()) {
        window_->close();
        // closePip() may be called before the closing signal fires, so clear state now.
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        window_->deleteLater();
        window_.clear();
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
    } else if (!pipConvId_.isEmpty()) {
        // Window was already gone; just clear the state.
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
    }
}

void
CallPipWindowManager::connectCallModel(const QString& accountId)
{
    disconnectCallModel();
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        callModelConnection_ = connect(accInfo.callModel.get(),
                                       &lrc::api::CallModel::callStatusChanged,
                                       this,
                                       &CallPipWindowManager::onCallStatusChanged);
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager: failed to connect callModel:" << e.what();
    }
}

void
CallPipWindowManager::disconnectCallModel()
{
    if (callModelConnection_)
        disconnect(callModelConnection_);
}
