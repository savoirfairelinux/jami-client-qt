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
#include "appsettingsmanager.h"
#include "pluginversionmanager.h"
#include "pluginstorelistmodel.h"
#include "preferenceitemlistmodel.h"

#include <QObject>
#include <QSortFilterProxyModel>
#include <QString>

class PluginVersionManager;
class PluginStoreListModel;
class AppSettingsManager;

class PluginAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_PROPERTY(int, callMediaHandlersListCount)
    QML_PROPERTY(int, chatHandlersListCount)

public:
    explicit PluginAdapter(LRCInstance* instance,
                           AppSettingsManager* settingsManager,
                           QObject* parent = nullptr,
                           QString baseUrl = "https://plugins.jami.net");
    ~PluginAdapter() = default;

    Q_INVOKABLE void getPluginsFromStore();
    Q_INVOKABLE void getPluginDetails(const QString& pluginId);
    Q_INVOKABLE void installRemotePlugin(const QString& pluginId);
    Q_INVOKABLE QString baseUrl() const;
    Q_INVOKABLE void checkVersionStatus(const QString& pluginId);
    Q_INVOKABLE bool isAutoUpdaterEnabled();
    Q_INVOKABLE void cancelDownload(const QString& pluginId);
    Q_INVOKABLE void setAutoUpdate(bool state);
    Q_INVOKABLE QString getIconUrl(const QString& pluginId) const;
    Q_INVOKABLE QString getBackgroundImageUrl(const QString& pluginId) const;
    Q_INVOKABLE bool isPluginAvailablePlatorm();

protected:
    Q_INVOKABLE QVariant getMediaHandlerSelectableModel(const QString& callId);
    Q_INVOKABLE QVariant getChatHandlerSelectableModel(const QString& accountId,
                                                       const QString& peerId);
    Q_INVOKABLE QVariant getPluginPreferencesCategories(const QString& pluginId,
                                                        const QString& accountId,
                                                        bool removeLast = false);
Q_SIGNALS:
    void storeNotAvailable();

private:
    void updateHandlersListCount();

    PluginStoreListModel* pluginStoreListModel_;
    PluginVersionManager* pluginVersionManager_;
    PluginListModel* pluginListModel_;

    std::unique_ptr<PluginHandlerListModel> pluginHandlerListModel_;

    LRCInstance* lrcInstance_;
    AppSettingsManager* settingsManager_;
    std::mutex mtx_;
    QString baseUrl_;
};
