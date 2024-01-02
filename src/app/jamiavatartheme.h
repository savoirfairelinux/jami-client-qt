/*
 * Copyright (C) 2017-2024 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
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

#include <QColor>

#pragma once

namespace JamiAvatarTheme {
static const QColor defaultAvatarColor_ = {0x9e, 0x9e, 0x9e}; // Grey
static const QColor avatarColors_[] {
    {0xf4, 0x43, 0x24}, // Red
    {0xe9, 0x1e, 0x63}, // Pink
    {0x9c, 0x27, 0xb0}, // Purple
    {0x67, 0x3a, 0xb7}, // Deep Purple
    {0x3f, 0x51, 0xb5}, // Indigo
    {0x21, 0x96, 0xf3}, // Blue
    {0x00, 0xbc, 0xd4}, // Cyan
    {0x00, 0x96, 0x88}, // Teal
    {0x4c, 0xaf, 0x50}, // Green
    {0x8b, 0xc3, 0x4a}, // Light Green
    {0x9e, 0x9e, 0x9e}, // Grey
    {0xcd, 0xdc, 0x39}, // Lime
    {0xff, 0xc1, 0x07}, // Amber
    {0xff, 0x57, 0x22}, // Deep Orange
    {0x79, 0x55, 0x48}, // Brown
    {0x60, 0x7d, 0x8b}  // Blue Grey
};
} // namespace JamiAvatarTheme
