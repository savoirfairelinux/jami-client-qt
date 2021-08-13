/**
 * Copyright (C) 2020 by Savoir-faire Linux
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

#include "pluginhandlerlistmodel.h"

#include "lrcinstance.h"

#include "api/pluginmodel.h"

PluginHandlerListModel::PluginHandlerListModel(QObject* parent,
                                               const QString& accountId,
                                               const QString& peerId,
                                               LRCInstance* instance)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;

    if (!peerId.isEmpty()) {
        set_accountId(accountId);
        set_peerId(peerId);
        isMediaHandler_ = false;
    } else {
        set_callId(accountId);
        isMediaHandler_ = true;
    }
}

PluginHandlerListModel::~PluginHandlerListModel() {}

int
PluginHandlerListModel::rowCount(const QModelIndex& parent) const
{
    if (!parent.isValid() && lrcInstance_) {
        /*
         * Count.
         */
        if (isMediaHandler_)
            return lrcInstance_->pluginModel().getCallMediaHandlers().size();
        else
            return lrcInstance_->pluginModel().getChatHandlers().size();
    }
    /*
     * A valid QModelIndex returns 0 as no entry has sub-elements.
     */
    return 0;
}

int
PluginHandlerListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    /*
     * Only need one column.
     */
    return 1;
}

QVariant
PluginHandlerListModel::data(const QModelIndex& index, int role) const
{
    QString name {""};
    QString id {""};
    QString iconPath {""};
    QString pluginId {""};
    bool loaded = false;

    if (isMediaHandler_) {
        auto mediahandlerList = lrcInstance_->pluginModel().getCallMediaHandlers();
        if (!index.isValid() || mediahandlerList.size() <= index.row()) {
            return QVariant();
        }

        auto details = lrcInstance_->pluginModel().getCallMediaHandlerDetails(
            mediahandlerList.at(index.row()));
        for (const auto& mediaHandler :
             lrcInstance_->pluginModel().getCallMediaHandlerStatus(callId_))
            if (mediaHandler == details.id)
                loaded = true;
        if (!details.pluginId.isEmpty()) {
            details.pluginId.remove(details.pluginId.size() - 5, 5);
        }

        name = details.name;
        id = mediahandlerList.at(index.row());
        iconPath = details.iconPath;
        pluginId = details.pluginId;

    } else {
        auto chathandlerList = lrcInstance_->pluginModel().getChatHandlers();
        if (!index.isValid() || chathandlerList.size() <= index.row()) {
            return QVariant();
        }

        auto details = lrcInstance_->pluginModel().getChatHandlerDetails(
            chathandlerList.at(index.row()));
        for (const auto& chatHandler :
             lrcInstance_->pluginModel().getChatHandlerStatus(accountId_, peerId_))
            if (chatHandler == details.id)
                loaded = true;
        if (!details.pluginId.isEmpty()) {
            details.pluginId.remove(details.pluginId.size() - 5, 5);
        }

        name = details.name;
        id = chathandlerList.at(index.row());
        iconPath = details.iconPath;
        pluginId = details.pluginId;
    }

    switch (role) {
    case Role::HandlerName:
        return QVariant(name);
    case Role::HandlerId:
        return QVariant(id);
    case Role::HandlerIcon:
        return QVariant(iconPath);
    case Role::IsLoaded:
        return QVariant(loaded);
    case Role::PluginId:
        return QVariant(pluginId);
    }
    return QVariant();
}

QHash<int, QByteArray>
PluginHandlerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[HandlerName] = "HandlerName";
    roles[HandlerId] = "HandlerId";
    roles[HandlerIcon] = "HandlerIcon";
    roles[IsLoaded] = "IsLoaded";
    roles[PluginId] = "PluginId";

    return roles;
}

void
PluginHandlerListModel::reset()
{
    beginResetModel();
    endResetModel();
}
