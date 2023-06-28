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
#include "networkmanager.h"
#include "lrcinstance.h"
#include "qmlregister.h"
#include "pluginstorelistmodel.h"

#include <QJsonDocument>
#include <utilsadapter.h>
#include <QJsonObject>
#include <QDir>
#include <QString>
#include <QJsonArray>

enum PluginInstallStatus {
    SUCCESS = 0,
    PLUGIN_ALREADY_INSTALLED = 100,
    PLUGIN_OLD_VERSION = 200,
    SIGNATURE_VERIFICATION_FAILED = 300,
    CERTIFICATE_VERIFICATION_FAILED = 400,
    INVALID_PLUGIN = 500,
} PluginInstallStatus;

PluginAdapter::PluginAdapter(LRCInstance* instance, QObject* parent, QString baseUrl)
    : QmlAdapterBase(instance, parent)
    , pluginVersionManager_(new PluginVersionManager(NULL, this))
    , pluginStoreListModel_(new PluginStoreListModel(this))
    , pluginListModel_(new PluginListModel(instance, this))
    , tempPath_(QDir::tempPath())
    , baseUrl(baseUrl)

{
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, pluginStoreListModel_, "PluginStoreListModel");
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, pluginListModel_, "PluginListModel")
    set_isEnabled(lrcInstance_->pluginModel().getPluginsEnabled());
    updateHandlersListCount();
    connect(&lrcInstance_->pluginModel(),
            &lrc::api::PluginModel::modelUpdated,
            this,
            &PluginAdapter::updateHandlersListCount);
    connect(this, &PluginAdapter::isEnabledChanged, this, &PluginAdapter::updateHandlersListCount);
    getPluginsFromStore();
}

void
PluginAdapter::getPluginsFromStore()
{
    pluginVersionManager_->sendGetRequest(QUrl(baseUrl), [this](const QByteArray& data) {
        auto result = QJsonDocument::fromJson(data).array();
        QList<QVariantMap> plugins;
        for (const auto& plugin : result) {
            plugins.append(plugin.toVariant().toMap());
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
    pluginVersionManager_->downloadFile(
        QUrl(baseUrl + "/download/" + pluginId),
        pluginId,
        0,
        [this, pluginId](bool success, const QString& error) {
            if (!success) {
                qDebug() << "Download Plugin error: " << error;
                changedStatus(pluginId, PluginStatus::FAILED);
                return;
            }
            auto res = lrcInstance_->pluginModel().installPlugin(tempPath_ + '/' + pluginId + ".jpl",
                                                                 true);
            if (res) {
                pluginStoreListModel_->removePlugin(pluginId);
                changedStatus(pluginId, PluginStatus::INSTALLED);
                pluginListModel_->addPlugin();
            } else {
                changedStatus(pluginId, PluginStatus::FAILED);
            }
        },
        tempPath_ + '/');
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
