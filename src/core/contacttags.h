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
#pragma once

#include "typedefs.h"

#include <QByteArray>
#include <QStringList>

#include <optional>

namespace lrc {
namespace contacttags {

// Contact metadata key holding the contact's tags as a UTF-8 JSON array of strings.
inline constexpr const char METADATA_KEY[] = "tag";

// Trimmed, non-empty, unique tags sorted case-insensitively.
QStringList normalize(const QStringList& tags);

QByteArray encode(const QStringList& tags);

// Returns std::nullopt if the value is not a JSON array of strings.
// An empty value decodes to no tags.
std::optional<QStringList> decode(const QByteArray& value);

// Tags stored in a contact metadata snapshot; malformed values yield no tags.
QStringList fromMetadata(const MapStringByteArray& metadata);

} // namespace contacttags
} // namespace lrc
