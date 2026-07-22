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

#include "htmlparser.h"

#include "globaltestenvironment.h"

TEST(HtmlParser, RepeatedCustomTagParsesAreIsolated)
{
    HtmlParser parser;

    for (int i = 0; i < 20; ++i) {
        ASSERT_TRUE(parser.parseHtmlString(QString("<custom-tag-%1></custom-tag-%1>").arg(i)));
        EXPECT_TRUE(parser.getTagsNodes({TidyTag_A}).isEmpty());
    }

    ASSERT_TRUE(parser.parseHtmlString("<a href=\"https://jami.net\">Jami</a>"));
    auto tagsNodes = parser.getTagsNodes({TidyTag_A});
    ASSERT_TRUE(tagsNodes.contains(TidyTag_A));
    ASSERT_EQ(tagsNodes[TidyTag_A].size(), 1);
    EXPECT_EQ(parser.getNodeAttr(tagsNodes[TidyTag_A].first(), TidyAttr_HREF),
              "https://jami.net");

    ASSERT_TRUE(parser.parseHtmlString("<p>No link</p>"));
    EXPECT_TRUE(parser.getTagsNodes({TidyTag_A}).isEmpty());
}
