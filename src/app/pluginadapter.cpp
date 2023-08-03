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

#include "pluginversionmanager.h"
#include "pluginlistmodel.h"
#include "pluginstorelistmodel.h"
#include "networkmanager.h"
#include "lrcinstance.h"
#include "utilsadapter.h"
#include "qmlregister.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDir>
#include <QString>

PluginAdapter::PluginAdapter(LRCInstance* instance, QObject* parent, QString baseUrl)
    : QmlAdapterBase(instance, parent)
    , pluginStoreListModel_(new PluginStoreListModel(instance, this))
    , pluginVersionManager_(new PluginVersionManager(instance, baseUrl, this))
    , pluginListModel_(new PluginListModel(instance, this))
    , lrcInstance_(instance)
    , tempPath_(QDir::tempPath())
    , baseUrl_(baseUrl)

{
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, pluginStoreListModel_, "PluginStoreListModel");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, pluginListModel_, "PluginListModel")
    updateHandlersListCount();
    connect(&lrcInstance_->pluginModel(),
            &lrc::api::PluginModel::modelUpdated,
            this,
            &PluginAdapter::updateHandlersListCount);
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
    connect(pluginVersionManager_,
            &PluginVersionManager::newVersionAvailable,
            pluginListModel_,
            &PluginListModel::onNewVersionAvailable);
    getPluginsFromStore();
}

void
PluginAdapter::getPluginsFromStore()
{
    const auto& errorHandler = connect(pluginVersionManager_,
                                       &PluginVersionManager::errorOccurred,
                                       this,
                                       [this](NetworkManager::GetError error, const QString& msg) {
                                           Q_EMIT storeNotAvailable();
                                       });
    pluginVersionManager_
        ->sendGetRequest(QUrl(baseUrl_ + "?arch=" + Utils::getPlatformString()),
                         [this, errorHandler](const QByteArray& data) {
                             auto result = QJsonDocument::fromJson(data).array();
                             auto pluginsInstalled = lrcInstance_->pluginModel().getPluginsId();
                             QList<QVariantMap> plugins;
                             for (const auto& plugin : result) {
                                 auto qPlugin = plugin.toVariant().toMap();
                                 if (!qPlugin.contains("id")) {
                                     qPlugin["id"] = qPlugin["name"];
                                 }
                                 qWarning() << qPlugin["id"];
                                 if (!pluginsInstalled.contains(qPlugin["id"].toString())) {
                                     plugins.append(qPlugin);
                                 }
                             }
                             pluginStoreListModel_->setPlugins(plugins);
                             disconnect(errorHandler);
                         });
}

void
PluginAdapter::getPluginDetails(const QString& pluginId)
{
    pluginVersionManager_->sendGetRequest(QUrl(baseUrl_ + "/details/" + pluginId
                                               + "?arch=" + Utils::getPlatformString()),
                                          [this](const QByteArray& data) {
                                              auto result = QJsonDocument::fromJson(data).object();
                                              // my response is a json object and I want to convert
                                              // it to a QVariantMap
                                              auto plugin = result.toVariantMap();
                                              if (!plugin.contains("id")) {
                                                  plugin["id"] = plugin["name"];
                                              }
                                              pluginStoreListModel_->addPlugin(plugin);
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

void
PluginAdapter::setAutoUpdate(bool state)
{
    pluginVersionManager_->setAutoUpdate(state);
}

void
PluginAdapter::cancelDownload(const QString& pluginId)
{
    pluginVersionManager_->cancelUpdate(pluginId);
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
    set_callMediaHandlersListCount(lrcInstance_->pluginModel().getCallMediaHandlers().size());
    set_chatHandlersListCount(lrcInstance_->pluginModel().getChatHandlers().size());
}

void
PluginAdapter::checkVersionStatus(const QString& pluginId)
{
    pluginVersionManager_->checkVersionStatus(pluginId);
}

QString
PluginAdapter::baseUrl() const
{
    return baseUrl_;
}

QString
PluginAdapter::getIconUrl(const QString& pluginId) const
{
    return baseUrl_ + "/icons/" + pluginId + "?arch=" + Utils::getPlatformString();
}

QString
PluginAdapter::getBackgroundImageUrl(const QString& pluginId) const
{
    return baseUrl_ + "/backgrounds/" + pluginId + "?arch=" + Utils::getPlatformString();
}
