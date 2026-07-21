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

#include <gtest/gtest.h>

/*!
 * WHEN  The same HtmlParser parses more than one document
 * THEN  The second parse should replace the previous DOM safely
 */
TEST(HtmlParser, RepeatedParsesReplacePreviousDocument)
{
    HtmlParser parser;

    EXPECT_TRUE(parser.parseHtmlString("<a id=\"first\" href=\"https://first.example\">first</a>"));
    auto firstLink = parser.getFirstTagNode(TidyTag_A);
    ASSERT_NE(firstLink, nullptr);
    EXPECT_EQ(parser.getNodeAttr(firstLink, TidyAttr_HREF), QString("https://first.example"));

    EXPECT_TRUE(parser.parseHtmlString("<title>Second</title><p>body</p>"));
    EXPECT_EQ(parser.getTagInnerHtml(TidyTag_TITLE), QString("Second"));
    EXPECT_EQ(parser.getFirstTagNode(TidyTag_A), nullptr);
}
