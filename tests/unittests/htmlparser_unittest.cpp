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

#include "globaltestenvironment.h"

#include "htmlparser.h"

class HtmlParserFixture : public ::testing::Test
{};

TEST_F(HtmlParserFixture, RepeatedCustomElementsParseWithoutDeclaredTagState)
{
    HtmlParser parser;

    for (auto i = 0; i < 20; ++i) {
        const auto expectedTitle = QString("Title %1").arg(i);
        const auto html = QString("<html><head><custom-preview-%1></custom-preview-%1>"
                                  "<meta property=\"og:title\" content=\"%2\"></head>"
                                  "<body><p>Body</p></body></html>")
                              .arg(i)
                              .arg(expectedTitle);

        ASSERT_TRUE(parser.parseHtmlString(html));
        const auto tags = parser.getTagsNodes({TidyTag_META});
        ASSERT_TRUE(tags.contains(TidyTag_META));
        const auto metaTags = tags.value(TidyTag_META);
        ASSERT_EQ(metaTags.size(), 1);
        EXPECT_TRUE(parser.getNodeText(metaTags.first()).contains(expectedTitle));
    }
}
