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

#include "webengineflags.h"

namespace {

void
appendFlag(QByteArray& flags, const QByteArray& flag)
{
    if (!flags.isEmpty())
        flags.append(' ');
    flags.append(flag);
}

} // namespace

QByteArray
makeWebEngineFlags(const QByteArray& existingFlags, bool jitless)
{
    auto flags = existingFlags;
    appendFlag(flags, "--disable-web-security");
    appendFlag(flags, "--single-process");
    appendFlag(flags, "--disable-gpu");
    if (jitless)
        appendFlag(flags, "--js-flags=--jitless");
    return flags;
}
