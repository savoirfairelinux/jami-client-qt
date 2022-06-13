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

#include "qmladapterbase.h"

#include "lrcinstance.h"

#include <QObject>

class WebViewAdapter final : public QmlAdapterBase
{
    Q_OBJECT

public:
    explicit WebViewAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~WebViewAdapter() = default;

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
     * @brief Generate a new, unique webViewId
     */
    Q_INVOKABLE QString getNextWebViewId();

Q_SIGNALS:
    void webViewMessageReceived(const QString& pluginId,
                                const QString& webViewId,
                                const QString& messageId,
                                const QString& payload);
    void testSignal();

public Q_SLOTS:
    void onNewWebViewMessage(const QString& pluginId,
                             const QString& webViewId,
                             const QString& messageId,
                             const QString& payload);

private:
    qint32 nextWebViewId = 1;
};
