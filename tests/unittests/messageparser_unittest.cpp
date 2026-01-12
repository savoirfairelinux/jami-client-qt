/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

class MessageParserFixture : public ::testing::Test
{
public:
    // Prepare unit test context. Called at
    // prior each unit test execution
    void SetUp() override {}

    // Close unit test context. Called
    // after each unit test ending
    void TearDown() override {}
};

/*!
 * WHEN  We parse a markdown text body with no link.
 * THEN  The HTML body should be returned correctly without the link.
 */
TEST_F(MessageParserFixture, TextIsParsedCorrectly)
{
    auto linkColor = QColor::fromRgb(0, 0, 255);
    auto backgroundColor = QColor::fromRgb(0, 0, 255);

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);
    QSignalSpy linkInfoReadySpy(globalEnv.messageParser.data(), &MessageParser::linkInfoReady);

    globalEnv.messageParser->parseMessage("msgId_01",
                                          "This is a **bold** text",
                                          true,
                                          linkColor,
                                          backgroundColor);

    // Wait for the messageParsed signal which should be emitted once.
    messageParsedSpy.wait();
    ASSERT_EQ(messageParsedSpy.count(), 1);

    QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
    EXPECT_TRUE(messageParserArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(0).toString(), "msgId_01");
    EXPECT_TRUE(messageParserArguments.at(1).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(1).toString(),
              "<style></style><p>This is a <strong>bold</strong> text</p>\n");

    // No link info should be returned.
    linkInfoReadySpy.wait();
    ASSERT_EQ(linkInfoReadySpy.count(), 0);
}

/*!
 * WHEN  We parse a text body with a link.
 * THEN  The HTML body should be returned correctly including the link.
 */
TEST_F(MessageParserFixture, ALinkIsParsedCorrectly)
{
    if (!globalEnv.connectivityMonitor->isOnline())
        GTEST_SKIP() << "ALinkIsParsedCorrectly requires Internet connectivity";

    auto linkColor = QColor::fromRgb(0, 0, 255);
    auto backgroundColor = QColor::fromRgb(0, 0, 255);

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);
    QSignalSpy linkInfoReadySpy(globalEnv.messageParser.data(), &MessageParser::linkInfoReady);

    // Parse a message with a link.
    globalEnv.messageParser->parseMessage("msgId_02",
                                          "https://www.google.com",
                                          true,
                                          linkColor,
                                          backgroundColor);

    // Wait for the messageParsed signal which should be emitted once.
    messageParsedSpy.wait();
    ASSERT_EQ(messageParsedSpy.count(), 1);

    QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
    EXPECT_TRUE(messageParserArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(0).toString(), "msgId_02");
    EXPECT_TRUE(messageParserArguments.at(1).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(1).toString(),
              "<style>a{color:#0000ff;}</style><p><a "
              "href=\"https://www.google.com\">https://www.google.com</a></p>\n");

    // Wait for the linkInfoReady signal which should be emitted once.
    linkInfoReadySpy.wait();
    ASSERT_EQ(linkInfoReadySpy.count(), 1);

    QList<QVariant> linkInfoReadyArguments = linkInfoReadySpy.takeFirst();
    EXPECT_TRUE(linkInfoReadyArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(linkInfoReadyArguments.at(0).toString(), "msgId_02");
    EXPECT_TRUE(linkInfoReadyArguments.at(1).typeId() == qMetaTypeId<QVariantMap>());
    QVariantMap linkInfo = linkInfoReadyArguments.at(1).toMap();
    EXPECT_EQ(linkInfo["url"].toString(), "https://www.google.com");
    // The rest of the link info is not tested here.
}

/*!
 * WHEN  We parse a text body with a link containing special characters ( +, -, _, etc.)
 * THEN  The HTML body should be returned correctly including the link.
 */
TEST_F(MessageParserFixture, AComplexLinkIsParsedCorrectly)
{
    auto linkColor = QColor::fromRgb(0, 0, 255);
    auto backgroundColor = QColor::fromRgb(0, 0, 255);

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);
    QSignalSpy linkInfoReadySpy(globalEnv.messageParser.data(), &MessageParser::linkInfoReady);

    struct TestCase {
        QString link;
        QString expectedMessage;
    };
    static const std::vector<TestCase> testCases = {
        {"https://review.jami.net/q/status:open+-is:wip",
         "<style>a{color:#0000ff;}</style><p><a href=\"https://review.jami.net/q/status:open+-is:wip\">https://review.jami.net/q/status:open+-is:wip</a></p>\n"},
        {"https://git.jami.net/savoirfairelinux/jami-client-qt/-/issues/1885#note_53907",
         "<style>a{color:#0000ff;}</style><p><a href=\"https://git.jami.net/savoirfairelinux/jami-client-qt/-/issues/1885#note_53907\">https://git.jami.net/savoirfairelinux/jami-client-qt/-/issues/1885#note_53907</a></p>\n"},
        {"https://www.youtube.com/watch?v=_tEL8bJ7yqU",
         "<style>a{color:#0000ff;}</style><p><a href=\"https://www.youtube.com/watch?v=_tEL8bJ7yqU\">https://www.youtube.com/watch?v=_tEL8bJ7yqU</a></p>\n"},
        {"https://www.youtube.com/watch?v=d_z77s7nifU",
         "<style>a{color:#0000ff;}</style><p><a href=\"https://www.youtube.com/watch?v=d_z77s7nifU\">https://www.youtube.com/watch?v=d_z77s7nifU</a></p>\n"},
        {"http://www.example.com/foo.php?bar[]=1&bar[]=2&bar[]=3",
         "<style>a{color:#0000ff;}</style><p><a href=\"http://www.example.com/foo.php?bar%5B%5D=1&amp;bar%5B%5D=2&amp;bar%5B%5D=3\">http://www.example.com/foo.php?bar[]=1&amp;bar[]=2&amp;bar[]=3</a></p>\n"},
    };

    static const QString expectedMessageTemplate = " <style>a{color:#0000ff;}</style><p><a href=\"%1\">%1</a></p>\n";

    for (const auto& testCase : testCases) {
        globalEnv.messageParser->parseMessage("msgId",
                                              testCase.link,
                                              false,
                                              linkColor,
                                              backgroundColor);

        // Wait for the messageParsed signal which should be emitted once.
        messageParsedSpy.wait();
        EXPECT_EQ(messageParsedSpy.count(), 1);

        QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
        EXPECT_TRUE(messageParserArguments.at(1).typeId() == qMetaTypeId<QString>());

        QString result = messageParserArguments.at(1).toString();
        QString expected = testCase.expectedMessage;
        // Convert to std::string to get better error messages in case of test
        // failure (GoogleTest is unable to print QStrings).
        EXPECT_EQ(result.toStdString(), expected.toStdString());
    }
}

/*!
 * WHEN  We parse a text body with end of line characters.
 * THEN  The HTML body should be returned correctly with the end of line characters.
 */
TEST_F(MessageParserFixture, EndOfLineCharactersAreParsedCorrectly)
{
    auto linkColor = QColor::fromRgb(0, 0, 255);
    auto backgroundColor = QColor::fromRgb(0, 0, 255);

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);

    // Parse a message with a link.
    globalEnv.messageParser->parseMessage("msgId_03",
                                          "Text with\n2 lines",
                                          true,
                                          linkColor,
                                          backgroundColor);

    // Wait for the messageParsed signal which should be emitted once.
    messageParsedSpy.wait();
    ASSERT_EQ(messageParsedSpy.count(), 1);

    QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
    EXPECT_TRUE(messageParserArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(0).toString(), "msgId_03");
    EXPECT_TRUE(messageParserArguments.at(1).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(1).toString(),
              "<style></style><p>Text with<br>\n2 lines</p>\n");
}

/*!
 * WHEN  We parse a text body with some fenced code.
 * THEN  The HTML body should be returned correctly with the code wrapped in a <pre> tag.
 */
TEST_F(MessageParserFixture, FencedCodeIsParsedCorrectly)
{
    auto linkColor = QColor::fromRgb(0, 0, 255);
    auto backgroundColor = QColor::fromRgb(0, 0, 255);

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);

    // Parse a message with a link.
    globalEnv.messageParser->parseMessage("msgId_04",
                                          "Text with \n```\ncode\n```",
                                          true,
                                          linkColor,
                                          backgroundColor);

    // Wait for the messageParsed signal which should be emitted once.
    messageParsedSpy.wait();
    ASSERT_EQ(messageParsedSpy.count(), 1);

    QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
    EXPECT_TRUE(messageParserArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(0).toString(), "msgId_04");
    EXPECT_TRUE(messageParserArguments.at(1).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(messageParserArguments.at(1).toString(),
              "<style>pre,code{background-color:#0000ff;color:#ffffff;white-space:pre-wrap;"
              "}</style><p>Text with</p>\n<pre><code>code\n</code></pre>\n");
}

/*!
 * WHEN  We parse a text body with a youtube link.
 * THEN  PreviewEngine::parseLink should be called with the correct arguments.
 */
TEST_F(MessageParserFixture, YoutubeLinkIsParsedCorrectly)
{
    if (!globalEnv.connectivityMonitor->isOnline())
        GTEST_SKIP() << "YoutubeLinkIsParsedCorrectly requires Internet connectivity";

    auto url = "https://www.youtube.com/watch?v=1234567890";
    auto msg = "blah blah " + QString(url) + " blah blah";

    QSignalSpy messageParsedSpy(globalEnv.messageParser.data(), &MessageParser::messageParsed);
    QSignalSpy linkInfoReadySpy(globalEnv.messageParser.data(), &MessageParser::linkInfoReady);

    // Parse a message with a link.
    globalEnv.messageParser->parseMessage("msgId_05",
                                          msg,
                                          true,
                                          QColor::fromRgb(0, 0, 255),
                                          QColor::fromRgb(0, 0, 255));

    // Wait for the messageParsed signal which should be emitted once.
    messageParsedSpy.wait();
    ASSERT_EQ(messageParsedSpy.count(), 1);

    QList<QVariant> messageParserArguments = messageParsedSpy.takeFirst();
    EXPECT_TRUE(messageParserArguments.at(0).typeId() == qMetaTypeId<QString>());

    // Wait for the linkInfoReady signal which should be emitted once.
    linkInfoReadySpy.wait();
    ASSERT_EQ(linkInfoReadySpy.count(), 1);

    QList<QVariant> linkInfoReadyArguments = linkInfoReadySpy.takeFirst();
    EXPECT_TRUE(linkInfoReadyArguments.at(0).typeId() == qMetaTypeId<QString>());
    EXPECT_EQ(linkInfoReadyArguments.at(0).toString(), "msgId_05");
    EXPECT_TRUE(linkInfoReadyArguments.at(1).typeId() == qMetaTypeId<QVariantMap>());
    QVariantMap linkInfo = linkInfoReadyArguments.at(1).toMap();
    EXPECT_EQ(linkInfo["url"].toString(), url);
}
