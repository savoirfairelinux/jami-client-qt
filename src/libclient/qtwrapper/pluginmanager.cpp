/******************************************************************************
 *    Copyright (C) 2014-2024 Savoir-faire Linux Inc.                         *
 *   Author : Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>   *
 *                                                                            *
 *   This library is free software; you can redistribute it and/or            *
 *   modify it under the terms of the GNU Lesser General Public               *
 *   License as published by the Free Software Foundation; either             *
 *   version 2.1 of the License, or (at your option) any later version.       *
 *                                                                            *
 *   This library is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 *   Lesser General Public License for more details.                          *
 *                                                                            *
 *   You should have received a copy of the Lesser GNU General Public License *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 *****************************************************************************/

#include "pluginmanager_wrap.h"

bool
PluginManagerInterface::loadPlugin(const QString& path)
{
    return libjami::loadPlugin(path.toStdString());
}

bool
PluginManagerInterface::unloadPlugin(const QString& path)
{
    return libjami::unloadPlugin(path.toStdString());
}

MapStringString
PluginManagerInterface::getPluginDetails(const QString& path)
{
    return convertMap(libjami::getPluginDetails(path.toStdString()));
}

QStringList
PluginManagerInterface::getInstalledPlugins()
{
    return convertStringList(libjami::getInstalledPlugins());
}

QStringList
PluginManagerInterface::getLoadedPlugins()
{
    return convertStringList(libjami::getLoadedPlugins());
}

int
PluginManagerInterface::installPlugin(const QString& jplPath, bool force)
{
    return libjami::installPlugin(jplPath.toStdString(), force);
}

int
PluginManagerInterface::uninstallPlugin(const QString& pluginRootPath)
{
    return libjami::uninstallPlugin(pluginRootPath.toStdString());
}

MapStringString
PluginManagerInterface::getPlatformInfo()
{
    return convertMap(libjami::getPlatformInfo());
}

QStringList
PluginManagerInterface::getCallMediaHandlers()
{
    return convertStringList(libjami::getCallMediaHandlers());
}

void
PluginManagerInterface::toggleCallMediaHandler(const QString& mediaHandlerId,
                                               const QString& callId,
                                               bool toggle)
{
    libjami::toggleCallMediaHandler(mediaHandlerId.toStdString(), callId.toStdString(), toggle);
}

QStringList
PluginManagerInterface::getChatHandlers()
{
    return convertStringList(libjami::getChatHandlers());
}

void
PluginManagerInterface::toggleChatHandler(const QString& chatHandlerId,
                                          const QString& accountId,
                                          const QString& peerId,
                                          bool toggle)
{
    libjami::toggleChatHandler(chatHandlerId.toStdString(),
                               accountId.toStdString(),
                               peerId.toStdString(),
                               toggle);
}

QStringList
PluginManagerInterface::getCallMediaHandlerStatus(const QString& callId)
{
    return convertStringList(libjami::getCallMediaHandlerStatus(callId.toStdString()));
}

MapStringString
PluginManagerInterface::getCallMediaHandlerDetails(const QString& mediaHandlerId)
{
    return convertMap(libjami::getCallMediaHandlerDetails(mediaHandlerId.toStdString()));
}

QStringList
PluginManagerInterface::getChatHandlerStatus(const QString& accountId, const QString& peerId)
{
    return convertStringList(
        libjami::getChatHandlerStatus(accountId.toStdString(), peerId.toStdString()));
}

MapStringString
PluginManagerInterface::getChatHandlerDetails(const QString& chatHandlerId)
{
    return convertMap(libjami::getChatHandlerDetails(chatHandlerId.toStdString()));
}

VectorMapStringString
PluginManagerInterface::getPluginPreferences(const QString& path, const QString& accountId)
{
    VectorMapStringString temp;
    for (auto x : libjami::getPluginPreferences(path.toStdString(), accountId.toStdString())) {
        temp.push_back(convertMap(x));
    }
    return temp;
}

bool
PluginManagerInterface::setPluginPreference(const QString& path,
                                            const QString& accountId,
                                            const QString& key,
                                            const QString& value)
{
    return libjami::setPluginPreference(path.toStdString(),
                                        accountId.toStdString(),
                                        key.toStdString(),
                                        value.toStdString());
}

MapStringString
PluginManagerInterface::getPluginPreferencesValues(const QString& path, const QString& accountId)
{
    return convertMap(
        libjami::getPluginPreferencesValues(path.toStdString(), accountId.toStdString()));
}

bool
PluginManagerInterface::resetPluginPreferencesValues(const QString& path, const QString& accountId)
{
    return libjami::resetPluginPreferencesValues(path.toStdString(), accountId.toStdString());
}
