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

#include "pluginadapter.h"

#include "networkmanager.h"
#include "lrcinstance.h"

#include <QJsonDocument>
#include <utilsadapter.h>
#include <QJsonObject>
#include <QDir>
#include <QTimer>
#include <QString>
#include <QJsonArray>

static constexpr int updatePeriod = 1000 * 60 * 15; // fifteen minutes

PluginAdapter::PluginAdapter(LRCInstance* instance, QObject* parent, QString baseUrl)
    : QmlAdapterBase(instance, parent)
    , lrcInstance_(instance)
    , pluginVersionManager_(new PluginVersionManager(instance, baseUrl, this))
    , pluginStoreListModel_(new PluginStoreListModel(this))
    , pluginListModel_(new PluginListModel(instance, this))
    , tempPath_(QDir::tempPath())
    , pluginsStoreTimer_(new QTimer(this))
    , baseUrl(baseUrl)

{
    set_isEnabled(lrcInstance_->pluginModel().getPluginsEnabled());
    updateHandlersListCount();
    connect(&lrcInstance_->pluginModel(),
            &lrc::api::PluginModel::modelUpdated,
            this,
            &PluginAdapter::updateHandlersListCount);
    connect(this, &PluginAdapter::isEnabledChanged, this, &PluginAdapter::updateHandlersListCount);
    connect(pluginVersionManager_,
            &PluginVersionManager::versionStatusChanged,
            pluginListModel_,
            &PluginListModel::onVersionStatusChanged);
    connect(pluginVersionManager_,
            &PluginVersionManager::versionStatusChanged,
            pluginStoreListModel_,
            &PluginStoreListModel::onVersionStatusChanged);
    connect(pluginStoreListModel_,
            &PluginStoreListModel::pluginAdded,
            this,
            &PluginAdapter::getPluginDetails);
    connect(pluginListModel_,
            &PluginListModel::versionCheckRequested,
            pluginVersionManager_,
            &PluginVersionManager::checkVersionStatus);
    connect(pluginListModel_,
            &PluginListModel::autoUpdateChanged,
            pluginVersionManager_,
            &PluginVersionManager::setAutoUpdate);
    connect(pluginListModel_,
            &PluginListModel::setVersionStatus,
            pluginStoreListModel_,
            &PluginStoreListModel::onVersionStatusChanged);
    connect(pluginsStoreTimer_, &QTimer::timeout, this, [this] { getPluginsFromStore(); });
    getPluginsFromStore();
    setPluginsStoreAutoRefresh(true);
}

PluginAdapter::~PluginAdapter()
{
    setPluginsStoreAutoRefresh(false);
}

void
PluginAdapter::getPluginsFromStore()
{
    pluginVersionManager_->sendGetRequest(QUrl(baseUrl), [this](const QByteArray& data) {
        auto result = QJsonDocument::fromJson(data).array();
        auto pluginsInstalled = lrcInstance_->pluginModel().getPluginsId();
        QList<QVariantMap> plugins;
        for (const auto& plugin : result) {
            auto qPlugin = plugin.toVariant().toMap();
            if (!pluginsInstalled.contains(qPlugin["id"].toString())) {
                qWarning() << qPlugin["id"];
                plugins.append(qPlugin);
            }
        }
        pluginStoreListModel_->setPlugins(plugins);
    });
}

void
PluginAdapter::getPluginDetails(const QString& pluginId)
{
    pluginVersionManager_->sendGetRequest(QUrl(baseUrl + "/details/" + pluginId),
                                          [this](const QByteArray& data) {
                                              auto result = QJsonDocument::fromJson(data).object();
                                              // my response is a json object and I want to convert
                                              // it to a QVariantMap
                                              pluginStoreListModel_->addPlugin(
                                                  result.toVariantMap());
                                          });
}

void
PluginAdapter::installRemotePlugin(const QString& pluginId)
{
    pluginVersionManager_->installRemotePlugin(pluginId);
}

bool
PluginAdapter::isAutoUpdaterEnabled()
{
    return pluginVersionManager_->isAutoUpdaterEnabled();
}

QVariant
PluginAdapter::getMediaHandlerSelectableModel(const QString& callId)
{
    pluginHandlerListModel_.reset(
        new PluginHandlerListModel(this, callId, QString(""), lrcInstance_));
    return QVariant::fromValue(pluginHandlerListModel_.get());
}

QVariant
PluginAdapter::getChatHandlerSelectableModel(const QString& accountId, const QString& peerId)
{
    pluginHandlerListModel_.reset(new PluginHandlerListModel(this, accountId, peerId, lrcInstance_));
    return QVariant::fromValue(pluginHandlerListModel_.get());
}

QVariant
PluginAdapter::getPluginPreferencesCategories(const QString& pluginId,
                                              const QString& accountId,
                                              bool removeLast)
{
    QStringList categories;
    auto preferences = lrcInstance_->pluginModel().getPluginPreferences(pluginId, accountId);
    for (auto& preference : preferences) {
        if (!preference["category"].isEmpty())
            categories.push_back(preference["category"]);
    }
    categories.removeDuplicates();
    if (removeLast)
        categories.pop_back();
    return categories;
}

void
PluginAdapter::updateHandlersListCount()
{
    if (isEnabled_) {
        set_callMediaHandlersListCount(lrcInstance_->pluginModel().getCallMediaHandlers().size());
        set_chatHandlersListCount(lrcInstance_->pluginModel().getChatHandlers().size());
    } else {
        set_callMediaHandlersListCount(0);
        set_chatHandlersListCount(0);
    }
}

void
PluginAdapter::checkVersionStatus(const QString& pluginId)
{
    pluginVersionManager_->checkVersionStatus(pluginId);
}

void
PluginAdapter::setPluginsStoreAutoRefresh(bool enabled)
{
    if (!enabled) {
        pluginsStoreTimer_->stop();
        return;
    }
    pluginsStoreTimer_->start(updatePeriod);
}
