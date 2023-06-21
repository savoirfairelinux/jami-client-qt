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

#include "lrcinstance.h"
#include "pluginversionmanager.h"
#include "qmlregister.h"
#include "pluginstorelistmodel.h"

#include <QJsonDocument>
#include <QString>
#include <QJsonArray>

QString BASE_URL = "http://127.0.0.1:3000";

PluginAdapter::PluginAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
    , pluginVersionManager_(new PluginVersionManager(NULL, this))
    , pluginStoreListModel_(new PluginStoreListModel(this))
    , pluginListModel_(new PluginListModel(instance, this))

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

    connect(pluginVersionManager_,
            &PluginVersionManager::downloadStarted,
            this,
            [this](const QString& pluginId) {
                qWarning() << "Download started";
                Q_EMIT changedStatus(pluginId, PluginStatus::DOWNLOADING);
            });

    connect(pluginVersionManager_,
            &PluginVersionManager::downloadFinished,
            this,
            [this](const QString& pluginId) {
                qWarning() << "Download finished";
                Q_EMIT changedStatus(pluginId, PluginStatus::DOWNLOADED);
            });
}

void
PluginAdapter::getPluginsFromStore()
{
    pluginVersionManager_->sendGetRequest(QUrl(BASE_URL), [this](const QByteArray& data) {
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
    pluginVersionManager_->sendGetRequest(QUrl(BASE_URL + "/details/" + pluginId),
                                          [](const QByteArray& plugin) {
                                              qDebug() << "Plugin: " << plugin;
                                          });
}

void
PluginAdapter::installRemotePlugin(const QString& pluginId)
{
    pluginVersionManager_->downloadFile(
        QUrl(BASE_URL + "/download/" + pluginId + ".jpl"),
        0,
        [this, pluginId](bool success, const QString& error) {
            if (!success) {
                qDebug() << "Download Plugin error: " << error;
                return;
            }
            auto res = lrcInstance_->pluginModel().installPlugin("/tmp/" + pluginId + ".jpl", false);

            // pluginListModel_->addPlugin(plugin);
        },
        "/tmp/");
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
