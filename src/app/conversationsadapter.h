/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

#pragma once

#include "lrcinstance.h"
#include "qmladapterbase.h"
#include "conversationlistmodel.h"
#include "searchresultslistmodel.h"

#include <QObject>
#include <QString>
#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

class SystemTray;

class ConversationsAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_PROPERTY(bool, filterRequests)
    QML_PROPERTY(int, totalUnreadMessageCount)
    QML_PROPERTY(int, pendingRequestCount)
    QML_RO_PROPERTY(QVariant, convListProxyModel)
    QML_RO_PROPERTY(QVariant, searchListProxyModel)

public:
    static ConversationsAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new ConversationsAdapter(
            qApp->property("SystemTray").value<SystemTray*>(),
            qApp->property("LRCInstance").value<LRCInstance*>(),
            qApp->property("ConvListProxyModel").value<ConversationListProxyModel*>(),
            qApp->property("ConvSearchListProxyModel").value<SelectableListProxyModel*>());
    }

    explicit ConversationsAdapter(SystemTray* systemTray,
                                  LRCInstance* instance,
                                  ConversationListProxyModel* convProxyModel,
                                  SelectableListProxyModel* searchProxyModel,
                                  QObject* parent = nullptr);
    ~ConversationsAdapter() = default;

public:
    void connectConversationModel();

    Q_INVOKABLE QString createSwarm(const QString& title,
                                    const QString& description,
                                    const QString& avatar,
                                    const VectorString& participants);
    Q_INVOKABLE void setFilter(const QString& filterString);
    Q_INVOKABLE void setFilterAndSelect(const QString& filterString);
    Q_INVOKABLE void ignoreFiltering(const QVariant& hightlighted);
    Q_INVOKABLE QVariantMap getConvInfoMap(const QString& convId);
    Q_INVOKABLE void restartConversation(const QString& convId);
    Q_INVOKABLE void updateConversationTitle(const QString& convId, const QString& newTitle);
    Q_INVOKABLE void popFrontError(const QString& convId);
    Q_INVOKABLE void ignoreActiveCall(const QString& convId,
                                      const QString& id,
                                      const QString& uri,
                                      const QString& device);
    Q_INVOKABLE void updateConversationDescription(const QString& convId,
                                                   const QString& newDescription);

    Q_INVOKABLE QString dialogId(const QString& peerUri);
    Q_INVOKABLE void openDialogConversationWith(const QString& peerUri);
Q_SIGNALS:
    void showConversation(const QString& accountId, const QString& convUid);
    void showSearchStatus(const QString& status);
    void textFilterChanged(const QString& text);

    void navigateToWelcomePageRequested();
    void conversationReady(const QString& convId);

private Q_SLOTS:
    void onCurrentAccountIdChanged();

    // cross-account slots
    void onNewUnreadInteraction(const QString& accountId,
                                const QString& convUid,
                                const QString& interactionId,
                                const interaction::Info& interaction);
    void onNewReadInteraction(const QString& accountId,
                              const QString& convUid,
                              const QString& interactionId);
    void onNewTrustRequest(const QString& accountId, const QString& convId, const QString& peerUri);
    void onTrustRequestTreated(const QString& accountId, const QString& peerUri);

    // per-account slots
    void onModelChanged();
    void onProfileUpdated(const QString&);
    void onConversationUpdated(const QString&);
    void onConversationRemoved(const QString&);
    void onFilterChanged();
    void onConversationCleared(const QString&);
    void onSearchStatusChanged(const QString&);
    void onSearchResultUpdated();
    void onSearchResultEnded();
    void onConversationReady(const QString&);
    void onBannedStatusChanged(const QString&, bool);

private:
    void updateConversation(const QString&);
    void updateConversationFilterData();

    SystemTray* systemTray_;

    QScopedPointer<ConversationListModel> convSrcModel_;
    ConversationListProxyModel* convModel_;
    QScopedPointer<SearchResultsListModel> searchSrcModel_;
    SelectableListProxyModel* searchModel_;

    std::atomic_bool selectFirst_ {false};
};
