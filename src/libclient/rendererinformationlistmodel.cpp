/*
 *  Copyright (C) 2024 Savoir-faire Linux Inc.
 *
 *  Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#include "rendererinformationlistmodel.h"

RendererInformationListModel::RendererInformationListModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int
RendererInformationListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return renderersInfoList_.size();
}

QVariant
RendererInformationListModel::data(const QModelIndex& index, int role) const
{
    using namespace RendererInfoList;

    if (role == Role::RENDERER_ID)
        return renderersInfoList_[index.row()].first;

    switch (role) {
#define X(var) \
    case Role::var: \
        return renderersInfoList_[index.row()].second[#var];
        RENDERERINFO_ROLES
#undef X
    }

    return QVariant();
}

void
RendererInformationListModel::updateFps(QString rendererId, QString fps)
{
    auto it = std::find_if(renderersInfoList_.begin(),
                           renderersInfoList_.end(),
                           [&rendererId](const auto& c) { return rendererId == c.first; });
    if (it != renderersInfoList_.end()) {
        // update fps
        auto index = std::distance(renderersInfoList_.begin(), it);
        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        it->second["FPS"] = fps;
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::FPS});
    }
}

void
RendererInformationListModel::addElement(QPair<QString, MapStringString> rendererInfo)
{
    // check element existence
    auto rendererId = rendererInfo.first;
    auto it = std::find_if(renderersInfoList_.begin(),
                           renderersInfoList_.end(),
                           [&rendererId](const auto& c) { return rendererId == c.first; });
    // if element doesn't exist
    if (it == renderersInfoList_.end()) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        renderersInfoList_.append(rendererInfo);
        endInsertRows();
    }
}

void
RendererInformationListModel::removeElement(QString rendererId)
{
    auto it = std::find_if(renderersInfoList_.begin(),
                           renderersInfoList_.end(),
                           [&rendererId](const auto& c) { return rendererId == c.first; });
    if (it != renderersInfoList_.end()) {
        auto elementIndex = std::distance(renderersInfoList_.begin(), it);
        beginRemoveRows(QModelIndex(), elementIndex, elementIndex);
        renderersInfoList_.remove(elementIndex);
        endRemoveRows();
    }
}

QHash<int, QByteArray>
RendererInformationListModel::roleNames() const
{
    using namespace RendererInfoList;
    QHash<int, QByteArray> roles;
#define X(var) roles[var] = #var;
    RENDERERINFO_ROLES
#undef X
    return roles;
}

void
RendererInformationListModel::reset()
{
    beginResetModel();
    renderersInfoList_.clear();
    endResetModel();
}
