/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 *
 * Author: Tobias Hildebrandt <tobias.hildebrandt@savoirfairelinux.com>
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

#include "webviewadapter.h"

#include "api/pluginmodel.h"

WebViewAdapter::WebViewAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    auto pluginModel = &lrcInstance_->pluginModel();

    // connect API model signals to our adapter slots
    QObject::connect(pluginModel,
                     &PluginModel::webViewMessageReceived,
                     this,
                     &WebViewAdapter::onNewWebViewMessage,
                     Qt::UniqueConnection);
}

void
WebViewAdapter::onNewWebViewMessage(const QString& pluginId,
                                    const QString& webViewId,
                                    const QString& messageId,
                                    const QString& payload)
{
    // emit a signal that QML can connect to
    Q_EMIT webViewMessageReceived(pluginId, webViewId, messageId, payload);
}

void
WebViewAdapter::sendWebViewMessage(const QString& pluginId,
                                   const QString& webViewId,
                                   const QString& messageId,
                                   const QString& payload)
{
    lrcInstance_->pluginModel().sendWebViewMessage(pluginId, webViewId, messageId, payload);
}

QString
WebViewAdapter::sendWebViewAttach(const QString& pluginId,
                                  const QString& accountId,
                                  const QString& webViewId,
                                  const QString& action)
{
    return lrcInstance_->pluginModel().sendWebViewAttach(pluginId, accountId, webViewId, action);
}

void
WebViewAdapter::sendWebViewDetach(const QString& pluginId, const QString& webViewId)
{
    lrcInstance_->pluginModel().sendWebViewDetach(pluginId, webViewId);
}

bool
WebViewAdapter::webViewPluginLoaded(const QString& pluginId)
{
    auto loadedPlugins = lrcInstance_->pluginModel().getLoadedPlugins();
    for (auto loadedPluginId : loadedPlugins) {
        auto pluginDatapath = loadedPluginId;
        if (pluginDatapath == pluginId) {
            return true;
        }
    }

    return false;
}

QString
WebViewAdapter::getNextWebViewId()
{
    auto id = nextWebViewId;
    nextWebViewId += 1;
    return QString::number(id);
}
