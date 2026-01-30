/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

#include "conversationlistproxymodel.h"

#include "uri.h"

ConversationListProxyModel::ConversationListProxyModel(QAbstractListModel* model, QObject* parent)
    : SelectableListProxyModel(model, parent)
{
    setSortRole(lrc::api::ConversationModel::Role::LastInteractionTimeStamp);
    sort(0, Qt::DescendingOrder);
    setFilterCaseSensitivity(Qt::CaseSensitivity::CaseInsensitive);
}

bool
ConversationListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);

    auto rx = filterRegularExpression();
    auto uriStripper = URI(rx.pattern());
    bool stripScheme = (uriStripper.schemeType() < URI::SchemeType::COUNT__);
    FlagPack<URI::Section> flags = URI::Section::USER_INFO | URI::Section::HOSTNAME | URI::Section::PORT;
    if (!stripScheme) {
        flags |= URI::Section::SCHEME;
    }
    rx.setPattern(uriStripper.format(flags));

    using namespace lrc::api::ConversationList;
    if (index.data(Role::Uris).toStringList().isEmpty()) {
        return false;
    }

    QStringList toFilter;
    toFilter += index.data(Role::Title).toString();
    toFilter += index.data(Role::Uris).toStringList();
    toFilter += index.data(Role::Monikers).toStringList();

    // requests
    auto isRequest = index.data(Role::IsRequest).toBool();
    bool requestFilter = filterRequests_ ? isRequest : !isRequest;

    bool match {false};

    // banned contacts require exact match
    if (ignored_.contains(index.data(Role::UID).toString())) {
        match = true;
    } else if (index.data(Role::IsBanned).toBool()) {
        if (!rx.pattern().isEmpty() && rx.isValid()) {
            Q_FOREACH (const auto& filter, toFilter) {
                auto matchResult = rx.match(filter);
                if (matchResult.hasMatch() && matchResult.captured(0) == filter) {
                    match = true;
                    break;
                }
            }
        }
    } else {
        Q_FOREACH (const auto& filter, toFilter)
            if (rx.isValid() && rx.match(filter).hasMatch()) {
                match = true;
                break;
            }
    }

    return requestFilter && match;
}

bool
ConversationListProxyModel::lessThan(const QModelIndex& left, const QModelIndex& right) const
{
    QVariant leftData = sourceModel()->data(left, sortRole());
    QVariant rightData = sourceModel()->data(right, sortRole());
    // we're assuming the sort role data type here is some integral time
    return leftData.toULongLong() < rightData.toULongLong();
}

void
ConversationListProxyModel::setFilterRequests(bool filterRequests)
{
    beginResetModel();
    filterRequests_ = filterRequests;
    endResetModel();
    updateSelection();
};
