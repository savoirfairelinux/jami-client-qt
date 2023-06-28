/*!
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

#include "qmladapterbase.h"
#include "pluginlistmodel.h"
#include "pluginhandlerlistmodel.h"
#include "pluginlistpreferencemodel.h"
#include "pluginversionmanager.h"
#include "preferenceitemlistmodel.h"
#include "pluginstorelistmodel.h"

#include <QObject>
#include <QSortFilterProxyModel>
#include <QString>

class PluginAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_PROPERTY(int, callMediaHandlersListCount)
    QML_PROPERTY(int, chatHandlersListCount)
    QML_PROPERTY(bool, isEnabled)

public:
    explicit PluginAdapter(LRCInstance* instance,
                           QObject* parent = nullptr,
                           QString baseUrl = "http://127.0.0.1:3000");
    ~PluginAdapter();
    Q_INVOKABLE void getPluginsFromStore();
    Q_INVOKABLE void getPluginDetails(const QString& pluginId);
    Q_INVOKABLE void installRemotePlugin(const QString& pluginId);
    Q_INVOKABLE QString baseUrl;
    Q_INVOKABLE void checkVersionStatus(const QString& pluginId);
    Q_INVOKABLE bool isAutoUpdaterEnabled();

protected:
    Q_INVOKABLE QVariant getMediaHandlerSelectableModel(const QString& callId);
    Q_INVOKABLE QVariant getChatHandlerSelectableModel(const QString& accountId,
                                                       const QString& peerId);
    Q_INVOKABLE QVariant getPluginPreferencesCategories(const QString& pluginId,
                                                        const QString& accountId,
                                                        bool removeLast = false);

private:
    void updateHandlersListCount();
    void setPluginsStoreAutoRefresh(bool enabled);

    std::unique_ptr<PluginHandlerListModel> pluginHandlerListModel_;
    PluginStoreListModel* pluginStoreListModel_;
    PluginVersionManager* pluginVersionManager_;
    PluginListModel* pluginListModel_;
    LRCInstance* lrcInstance_;
    std::mutex mtx_;
    QString tempPath_;
    QTimer* pluginsStoreTimer_;
};
