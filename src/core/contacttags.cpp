/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
#include "contacttags.h"

#include <QJsonArray>
#include <QJsonDocument>

namespace lrc {
namespace contacttags {

QStringList
normalize(const QStringList& tags)
{
    QStringList result;
    for (const auto& tag : tags) {
        auto trimmed = tag.trimmed();
        if (!trimmed.isEmpty() && !result.contains(trimmed))
            result.append(std::move(trimmed));
    }
    result.sort(Qt::CaseInsensitive);
    return result;
}

QByteArray
encode(const QStringList& tags)
{
    return QJsonDocument(QJsonArray::fromStringList(normalize(tags))).toJson(QJsonDocument::Compact);
}

std::optional<QStringList>
decode(const QByteArray& value)
{
    if (value.isEmpty())
        return QStringList {};
    const auto document = QJsonDocument::fromJson(value);
    if (!document.isArray())
        return std::nullopt;
    QStringList tags;
    for (const auto& entry : document.array()) {
        if (!entry.isString())
            return std::nullopt;
        tags.append(entry.toString());
    }
    return normalize(tags);
}

QStringList
fromMetadata(const MapStringByteArray& metadata)
{
    const auto it = metadata.constFind(QString::fromLatin1(METADATA_KEY));
    if (it == metadata.cend())
        return {};
    if (auto tags = decode(*it))
        return *tags;
    LC_WARN << "Ignoring malformed contact tags metadata";
    return {};
}

} // namespace contacttags
} // namespace lrc
