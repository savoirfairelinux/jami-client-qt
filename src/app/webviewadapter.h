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

#pragma once

#include "appsettingsmanager.h"
#include "lrcinstance.h"
#include "qmladapterbase.h"

#include <QObject>
#include <QMap>

class WebViewAdapter final : public QmlAdapterBase
{
    Q_OBJECT

public:
    explicit WebViewAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~WebViewAdapter() = default;

Q_SIGNALS:
    void webViewMessageReceived(const QString& pluginId,
                                const QString& webViewId,
                                const QString& messageId,
                                const QString& payload);

protected:
    void safeInit() override;

private Q_SLOTS:
    void onWebViewMessageReceived(const QString& pluginId,
                                  const QString& webViewId,
                                  const QString& messageId,
                                  const QString& payload);

public:
    Q_INVOKABLE void sendWebViewMessage(const QString& pluginId,
                                        const QString& webViewId,
                                        const QString& messageId,
                                        const QString& payload);

    Q_INVOKABLE QString sendWebViewAttach(const QString& pluginId,
                                          const QString& accountId,
                                          const QString& webViewId,
                                          const QString& action);

    Q_INVOKABLE void sendWebViewDetach(const QString& pluginId, const QString& webViewId);

    /**
     * @brief Returns whether or not a webview plugin is loaded
     * @param pluginId the plugin id (not the datapath!)
     */
    Q_INVOKABLE bool webViewPluginLoaded(const QString& pluginId);

    /**
     * @brief Generate a new, unique webViewId
     */
    Q_INVOKABLE QString getNextWebViewId();

private:
    qint32 nextWebViewId = 1;
};
