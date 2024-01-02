/**
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include <memory>
#include "networkmanager.h"

class QString;
class LRCInstance;
class AppSettingsManager;

#define PLUGIN_STATUS_ROLES \
    X(INSTALLABLE) \
    X(DOWNLOADING) \
    X(INSTALLING) \
    X(INSTALLED) \
    X(FAILED) \
    X(UPDATABLE)

namespace PluginStatus {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    PLUGIN_STATUS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace PluginStatus

class PluginVersionManager final : public NetworkManager
{
    Q_OBJECT
public:
    explicit PluginVersionManager(LRCInstance* instance,
                                  AppSettingsManager* settingsManager,
                                  QObject* parent = nullptr);
    ~PluginVersionManager();

    Q_INVOKABLE bool isAutoUpdaterEnabled();

    Q_INVOKABLE void cancelUpdate(const QString& pluginId);
    int downloadFile(const QUrl& url,
                     const QString& pluginId,
                     int replyId,
                     std::function<void(bool, const QString&)>&& onDoneCallback,
                     const QString& filePath,
                     const QString& extension = ".jpl");
    void installRemotePlugin(const QString& pluginId);

public Q_SLOTS:
    void checkVersionStatus(const QString& pluginId);
    void setAutoUpdate(bool state);

Q_SIGNALS:
    void versionStatusChanged(const QString& pluginId, PluginStatus::Role status);
    void newVersionAvailable(const QString& pluginId, const QString& version);

private:
    bool checkVersion(const QString& installedVersion, const QString& remoteVersion) const;
    QString baseUrl;
    bool autoUpdateCheck = false;
    QMap<QString, int> pluginRepliesId {};
    struct Impl;
    friend struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
Q_DECLARE_METATYPE(PluginVersionManager*)
