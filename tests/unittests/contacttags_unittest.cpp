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

#include <gtest/gtest.h>

using namespace lrc;

TEST(ContactTags, NormalizeTrimsDropsEmptyDedupesAndSorts)
{
    const QStringList tags {" work ", "", "Family", "work", "  ", "apple"};

    EXPECT_EQ(contacttags::normalize(tags), (QStringList {"apple", "Family", "work"}));
}

TEST(ContactTags, RoundTripsThroughJson)
{
    const QStringList tags {"Café", "Family", "work"};

    const auto encoded = contacttags::encode(tags);

    EXPECT_EQ(encoded, QByteArray(R"(["Café","Family","work"])"));
    EXPECT_EQ(contacttags::decode(encoded), tags);
}

TEST(ContactTags, EmptyValueDecodesToNoTags)
{
    EXPECT_EQ(contacttags::decode({}), QStringList {});
}

TEST(ContactTags, RejectsValuesThatAreNotStringArrays)
{
    EXPECT_FALSE(contacttags::decode("not json").has_value());
    EXPECT_FALSE(contacttags::decode(R"({"tag":"work"})").has_value());
    EXPECT_FALSE(contacttags::decode(R"(["work",1])").has_value());
}

TEST(ContactTags, FromMetadataReadsTheTagKey)
{
    MapStringByteArray metadata;
    metadata["other"] = R"(["ignored"])";
    metadata[contacttags::METADATA_KEY] = R"(["work"," Family "])";

    EXPECT_EQ(contacttags::fromMetadata(metadata), (QStringList {"Family", "work"}));
}

TEST(ContactTags, FromMetadataIgnoresMalformedValues)
{
    MapStringByteArray metadata;
    metadata[contacttags::METADATA_KEY] = "[broken";

    EXPECT_TRUE(contacttags::fromMetadata(metadata).isEmpty());
}
