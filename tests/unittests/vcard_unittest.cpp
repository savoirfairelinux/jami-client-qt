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

#include "core/vcard.h"

#include <gtest/gtest.h>

TEST(VCard, PhotoSkipsEmptyPhotoEntry)
{
    const auto vCard = lrc::vCard::utils::toHashMap("BEGIN:VCARD\n"
                                                    "FN:Alice\n"
                                                    "PHOTO:aW1hZ2U=\n"
                                                    "PHOTO;ENCODING=BASE64;TYPE=PNG:\n"
                                                    "VERSION:2.1\n"
                                                    "END:VCARD\n");

    EXPECT_EQ(lrc::vCard::utils::photo(vCard), QByteArray("aW1hZ2U="));
}
