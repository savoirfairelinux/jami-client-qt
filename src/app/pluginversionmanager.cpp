/**
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

#include "pluginversionmanager.h"
#include "networkmanager.h"
#include "appsettingsmanager.h"
#include "lrcinstance.h"
#include "api/pluginmodel.h"

#include <QMap>
#include <QTimer>
#include <QDir>

static constexpr int updatePeriod = 1000 * 60 * 60 * 24; // one day in millis

struct PluginVersionManager::Impl : public QObject
{
public:
    Impl(LRCInstance* instance, PluginVersionManager& parent)
        : QObject(nullptr)
        , parent_(parent)
        , settingsManager_(new AppSettingsManager(this))
        , lrcInstance_(instance)
        , updateTimer_(new QTimer(this))
    {
        connect(updateTimer_, &QTimer::timeout, this, [this] { checkForUpdates(); });
        connect(&parent_, &NetworkManager::downloadFinished, this, [this](int replyId) {
            auto pluginsId = parent_.pluginRepliesId.keys(replyId);
            if (pluginsId.size() == 0) {
                return;
            }
            for (const auto& pluginId : qAsConst(pluginsId)) {
                parent_.pluginRepliesId.remove(pluginId);
            }
        });
        checkForUpdates();
        setAutoUpdateCheck(true);
    }

    ~Impl()
    {
        setAutoUpdateCheck(false);
    }

    void checkForUpdates()
    {
        if (!lrcInstance_) {
            return;
        }
        for (const auto& plugin : lrcInstance_->pluginModel().getInstalledPlugins()) {
            checkVersionStatusFromPath(plugin);
        }
    }

    void cancelUpdate(const QString& pluginId)
    {
        if (!parent_.pluginRepliesId.contains(pluginId)) {
            return;
        }
        parent_.cancelDownload(parent_.pluginRepliesId[pluginId]);
        parent_.versionStatusChanged(pluginId, PluginStatus::Role::INSTALLABLE);
    };

    bool isAutoUpdaterEnabled()
    {
        return settingsManager_->getValue(Settings::Key::PluginAutoUpdate).toBool();
    }

    void setAutoUpdate(bool state)
    {
        settingsManager_->setValue(Settings::Key::PluginAutoUpdate, state);
    }

    void checkVersionStatus(const QString& pluginId)
    {
        checkVersionStatusFromPath(lrcInstance_->pluginModel().getPluginPath(pluginId));
    }

    void checkVersionStatusFromPath(const QString& pluginPath)
    {
        if (!lrcInstance_) {
            return;
        }

        auto plugin = lrcInstance_->pluginModel().getPluginDetails(pluginPath);
        if (plugin.version == "" || plugin.id == "") {
            Q_EMIT parent_.versionStatusChanged(plugin.id, PluginStatus::Role::FAILED);
            return;
        }

        parent_.sendGetRequest(QUrl(settingsManager_->getValue("PluginStoreEndpoint").toString()
                                    + "/versions/" + plugin.id + "?arch="
                                    + lrcInstance_->pluginModel().getPlatformInfo()["os"]),
                               [this, plugin](const QByteArray& data) {
                                   // `data` represents the version in this case.
                                   if (plugin.version < data) {
                                       if (isAutoUpdaterEnabled()) {
                                           installRemotePlugin(plugin.id);
                                           return;
                                       }
                                   }
                                   parent_.versionStatusChanged(plugin.id,
                                                                PluginStatus::Role::UPDATABLE);
                               });
    }

    void installRemotePlugin(const QString& pluginId)
    {
        parent_.downloadFile(
            QUrl(settingsManager_->getValue("PluginStoreEndpoint").toString() + "/download/"
                 + lrcInstance_->pluginModel().getPlatformInfo()["os"] + "/" + pluginId),
            pluginId,
            0,
            [this, pluginId](bool success, const QString& error) {
                if (!success) {
                    qDebug() << "Download Plugin error: " << error;
                    parent_.versionStatusChanged(pluginId, PluginStatus::Role::FAILED);
                    return;
                }
                QThreadPool::globalInstance()->start([this, pluginId] {
                    auto res = lrcInstance_->pluginModel()
                                   .installPlugin(QDir(QDir::tempPath()).filePath(pluginId + ".jpl"),
                                                  false);
                    if (res) {
                        parent_.versionStatusChanged(pluginId, PluginStatus::Role::INSTALLED);
                    } else {
                        parent_.versionStatusChanged(pluginId, PluginStatus::Role::FAILED);
                    }
                });
                parent_.versionStatusChanged(pluginId, PluginStatus::Role::INSTALLING);
            },
            QDir::tempPath());
        Q_EMIT parent_.versionStatusChanged(pluginId, PluginStatus::Role::DOWNLOADING);
    }

    void setAutoUpdateCheck(bool state)
    {
        // Quiet check for updates periodically, if set to.
        if (!state) {
            updateTimer_->stop();
            return;
        }
        updateTimer_->start(updatePeriod);
    };

    PluginVersionManager& parent_;
    AppSettingsManager* settingsManager_ {nullptr};
    LRCInstance* lrcInstance_ {nullptr};
    QTimer* updateTimer_;
};

PluginVersionManager::PluginVersionManager(LRCInstance* instance, QObject* parent)
    : NetworkManager(&instance->connectivityMonitor(), parent)
    , pimpl_(std::make_unique<Impl>(instance, *this))
{}

PluginVersionManager::~PluginVersionManager()
{
    for (const auto& pluginReplyId : pluginRepliesId.values()) {
        cancelDownload(pluginReplyId);
    }
    pluginRepliesId.clear();
}

void
PluginVersionManager::cancelUpdate(const QString& pluginId)
{
    pimpl_->cancelUpdate(pluginId);
}

bool
PluginVersionManager::isAutoUpdaterEnabled()
{
    return pimpl_->isAutoUpdaterEnabled();
}

void
PluginVersionManager::setAutoUpdate(bool state)
{
    pimpl_->setAutoUpdate(state);
}

int
PluginVersionManager::downloadFile(const QUrl& url,
                                   const QString& pluginId,
                                   int replyId,
                                   std::function<void(bool, const QString&)>&& onDoneCallback,
                                   const QString& filePath,
                                   const QString& extension)
{
    auto reply = NetworkManager::downloadFile(url,
                                              replyId,
                                              std::move(onDoneCallback),
                                              filePath,
                                              extension);
    pluginRepliesId[pluginId] = reply;
    return reply;
}

void
PluginVersionManager::checkVersionStatus(const QString& pluginId)
{
    pimpl_->checkVersionStatus(pluginId);
}

void
PluginVersionManager::installRemotePlugin(const QString& pluginId)
{
    pimpl_->installRemotePlugin(pluginId);
}
