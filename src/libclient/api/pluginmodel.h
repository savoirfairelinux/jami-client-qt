/*!
 *   Copyright (C) 2018-2025 Savoir-faire Linux Inc.
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2.1 of the License, or (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma once

// std
#include <memory>
#include <string>
#include <vector>

// Qt
#include <qobject.h>

// LRC
#include "typedefs.h"

namespace lrc {

namespace api {

namespace plugin {
/**
 * This class describes current plugin Details
 */
struct PluginDetails
{
    QString path = "";
    QString id = "";
    QString name = "";
    QString description = "";
    QString version = "";
    QString author = "";
    QString iconPath = "";
    QString backgroundPath = "";
    bool loaded = false;
};

struct PluginHandlerDetails
{
    QString id = "";
    QString name = "";
    QString iconPath = "";
    QString pluginId = "";
};
} // namespace plugin

class LIB_EXPORT PluginModel : public QObject
{
    Q_OBJECT
public:
    PluginModel();
    ~PluginModel();

    /**
     * Get list of installed plugins
     * @return plugins installed
     */
    VectorString getInstalledPlugins() const;

    /**
     * Get list of loaded plugins
     * @return plugins loaded
     */
    VectorString getLoadedPlugins() const;

    /**
     * Get details of installed plugin
     * @return plugin Details
     */
    plugin::PluginDetails getPluginDetails(const QString& path);

    /**
     * Install plugin
     * @return true if plugin was succesfully installed
     */
    Q_INVOKABLE bool installPlugin(const QString& jplPath, bool force);

    /**
     * Uninstall plugin
     * @return true if plugin was succesfully uninstalled
     */
    Q_INVOKABLE bool uninstallPlugin(const QString& rootPath);

    /**
     * @brief get the plugin path
     * @param pluginId
     * @return plugin path
     */
    QString getPluginPath(const QString& pluginId);

    Q_INVOKABLE MapStringString getPlatformInfo();
    /**
     * @brief fetch all plugins path and id
     *
     */
    void setPluginsPath();

    /**
     * @brief get all plugins id
     * @return plugins id
     */
    VectorString getPluginsId();

    /**
     * Load plugin
     * @return true if plugin was succesfully loaded
     */
    Q_INVOKABLE bool loadPlugin(const QString& path);

    /**
     * Unload plugin
     * @return true if plugin was succesfully unloaded
     */
    Q_INVOKABLE bool unloadPlugin(const QString& path);

    /**
     * List all plugins Media Handlers
     * @return List of all plugins Media Handlers
     */
    VectorString getCallMediaHandlers() const;

    /**
     * Toggle media handler
     */
    Q_INVOKABLE void toggleCallMediaHandler(const QString& mediaHandlerId,
                                            const QString& callId,
                                            bool toggle);

    VectorString getChatHandlers() const;

    /**
     * Toggle chat handler
     */
    Q_INVOKABLE void toggleChatHandler(const QString& chatHandlerId,
                                       const QString& accountId,
                                       const QString& peerId,
                                       bool toggle);

    /**
     * Verify if there is an active plugin media handler
     * @return Map with name and status
     */
    VectorString getCallMediaHandlerStatus(const QString& callId);

    /**
     * Get details of installed plugins media handlers
     * @return Media Handler Details
     */
    plugin::PluginHandlerDetails getCallMediaHandlerDetails(const QString& mediaHandlerId);

    VectorString getChatHandlerStatus(const QString& accountId, const QString& peerId);

    plugin::PluginHandlerDetails getChatHandlerDetails(const QString& chatHandlerId);

    /**
     * Get preferences map of installed plugin
     * @return Plugin preferences infos vector
     */
    Q_INVOKABLE VectorMapStringString getPluginPreferences(const QString& path,
                                                           const QString& accountId);

    /**
     * Modify preference of installed plugin
     * @return true if preference was succesfully modified
     */
    Q_INVOKABLE bool setPluginPreference(const QString& path,
                                         const QString& accountId,
                                         const QString& key,
                                         const QString& value);

    /**
     * Get preferences values of installed plugin
     * @return Plugin preferences map
     */
    MapStringString getPluginPreferencesValues(const QString& path, const QString& accountId);

    /**
     * Reste preferences values of installed plugin to default values
     * @return true if preference was succesfully reset
     */
    Q_INVOKABLE bool resetPluginPreferencesValues(const QString& path, const QString& accountId);
Q_SIGNALS:
    void chatHandlerStatusUpdated(bool isVisible);
    void modelUpdated();

private:
    MapStringString pluginsPath_ = {};
};

} // namespace api
} // namespace lrc
Q_DECLARE_METATYPE(lrc::api::PluginModel*)
