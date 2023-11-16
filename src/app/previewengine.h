/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "networkmanager.h"

class PreviewEngine final : public NetworkManager
{
    Q_OBJECT
    Q_DISABLE_COPY(PreviewEngine)
public:
    PreviewEngine(ConnectivityMonitor* cm, QObject* parent = nullptr);
    ~PreviewEngine();

Q_SIGNALS:
    void parseLink(const QString& id, const QString& link);
    void infoReady(const QString& id, const QVariantMap& info);

private:
    Q_SLOT void onParseLink(const QString& id, const QString& link);
    Q_SIGNAL void htmlReady(const QString& id, const QString& link, const QByteArray& data);

    class Parser;
    QScopedPointer<Parser> parser_;
    QThread* parserThread_;
};
