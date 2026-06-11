/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

#include "mediacodeclistmodel.h"

#include "lrcinstance.h"

#include "api/account.h"
#include "api/codecmodel.h"

MediaCodecListModel::MediaCodecListModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{}

MediaCodecListModel::~MediaCodecListModel() {}

bool
MediaCodecListModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    auto index = sourceModel()->index(sourceRow, 0, sourceParent);
    auto type = index.data(lrc::api::CodecList::Type).toString();

    if (mediaType_ == VIDEO) {
        // Filter out video codecs with empty names
        auto name = index.data(lrc::api::CodecList::MediaCodecName).toString();
        return type == "VIDEO" && !name.isEmpty();
    }
    return type == "AUDIO";
}

void
MediaCodecListModel::reset()
{
    refreshFilter();
}

LRCInstance*
MediaCodecListModel::lrcInstance() const
{
    return lrcInstance_;
}

void
MediaCodecListModel::setLrcInstance(LRCInstance* instance)
{
    if (lrcInstance_ == instance)
        return;
    lrcInstance_ = instance;
    Q_EMIT lrcInstanceChanged();
    connect(lrcInstance_, &LRCInstance::currentAccountIdChanged, this, &MediaCodecListModel::connectAccount);
    connectAccount();
}

int
MediaCodecListModel::mediaType()
{
    return mediaType_;
}

void
MediaCodecListModel::setMediaType(int mediaType)
{
    if (mediaType_ != mediaType) {
        mediaType_ = mediaType;
        Q_EMIT mediaTypeChanged();
        refreshFilter();
    }
}

void
MediaCodecListModel::connectAccount()
{
    if (!lrcInstance_ || lrcInstance_->get_currentAccountId().isEmpty()) {
        setSourceModel(nullptr);
        return;
    }
    setSourceModel(lrcInstance_->getCurrentAccountInfo().codecModel.get());
}

void
MediaCodecListModel::refreshFilter()
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
    beginFilterChange();
    endFilterChange(QSortFilterProxyModel::Direction::Rows);
#else
    invalidateFilter();
#endif
}
