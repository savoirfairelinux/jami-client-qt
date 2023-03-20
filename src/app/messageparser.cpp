/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

#include "messageparser.h"

#include "previewengine.h"
#include "htmlparser.h"

#include <QRegularExpression>
#include <QtConcurrent>

#include "md4c-html.h"

MessageParser::MessageParser(PreviewEngine* previewEngine, QObject* parent)
    : QObject(parent)
    , previewEngine_(previewEngine)
    , htmlParser_(new HtmlParser(this))
{
    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessageParser::linkInfoReady);

    // // Test finding all non-code blocks in markdown text.
    // QString pattern = "`{1,3}([\\s\\S]*?)`{1,3}";
    // static QRegularExpression re(pattern);
    // QString testString
    //     = "some text ```some code  \n``` more text ```more code``` and more text `tiny code`";
    // qDebug() << testString;
    // auto match = re.globalMatch(testString);
    // // We need to invert the match, because the regex matches the code blocks.
    // // We need to track the indices and lengths of the code blocks and then use those to
    // // find the text between them.
    // QVector<QPair<int, int>> codeBlockInfo;
    // while (match.hasNext()) {
    //     auto m = match.next();
    //     codeBlockInfo.push_back({m.capturedStart(), m.capturedLength()});
    // }
    // qDebug() << "Code block info:" << codeBlockInfo;
    // // Now we can find the text between the code blocks.
    // int start = 0;
    // int end = 0;
    // for (auto& info : codeBlockInfo) {
    //     end = info.first;
    //     qDebug() << "Text between code blocks:" << testString.mid(start, end - start);
    //     start = info.first + info.second;
    // }
    // // There may be some text after the last code block.
    // if (start < testString.size()) {
    //     qDebug() << "Text after last code block:" << testString.mid(start);
    // }
}

void
MessageParser::parseMessage(const QString& messageId,
                            const QString& msg,
                            bool previewLinks,
                            const QColor& linkColor)
{
    // Run everything here on a separate thread.
    std::ignore = QtConcurrent::run(
        [this, messageId, msg = msg, previewLinks, linkColor]() mutable -> void {
            preprocessMarkdown(msg);
            auto html = markdownToHtml(msg.toUtf8().constData());

            qDebug() << "HTML:" << html;

            // Now that we have the HTML, we can parse it to get a list of tags and their values.
            // We are only interested in the <a> and <pre> tags.
            htmlParser_->parseHtmlString(html);
            auto tagsMap = htmlParser_->getTags({TidyTag_A, TidyTag_PRE});

            // Check for any <pre> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. add some CSS to make them wrap.
            if (tagsMap.contains(QString::number(TidyTag_PRE))) {
                // Find the content of the <pre><code> tag pairs.
                static QRegularExpression codeRegex("<pre><code>((.|\n)*?)</code></pre>");
                auto match = codeRegex.match(html);
                for (int i = 0; i < match.lastCapturedIndex(); i += 2) {
                    // Get the start and end positions of the match.
                    auto start = match.capturedStart(i + 1);
                    auto end = match.capturedEnd(i + 1);
                    auto code = match.captured(i + 1);
                    // Remove trailing whitespace.
                    // Replace the double-space + linefeeds in code blocks with a single linefeed.
                    static QRegularExpression codeNewlineRegex("  \n");
                    code.replace(codeNewlineRegex, "\n");
                    // Remove the linefeed at the end of the code block (if there is one).
                    code.chop(code.endsWith("\n"));
                    // Replace the match with the new string.
                    html.replace(start, end - start, code);
                }

                html.prepend(QString("<style>pre,code{background-color:%1;"
                                     "color:%2;white-space:pre-wrap;}</style>")
                                 .arg("#f0f0f0")
                                 .arg("#222222"));
            }

            qDebug() << "HTML2:" << html;

            // Check for any <a> tags. If there are any, we need to:
            // 1. add some CSS to color them.
            // 2. parse them to get a preview IF the user has enabled link previews.
            if (tagsMap.contains(QString::number(TidyTag_A))) {
                html.prepend(QString("<style>a{color:%1;}</style>").arg(linkColor.name()));

                // Update the UI before we start parsing the link.
                Q_EMIT messageParsed(messageId, html);

                // If the user has enabled link previews, then we need to generate the link preview.
                if (previewLinks) {
                    // Get the first link in the message.
                    auto anchorTag = tagsMap[QString::number(TidyTag_A)].toList().first().toString();
                    static QRegularExpression hrefRegex("href=\"(.*?)\"");
                    auto match = hrefRegex.match(anchorTag);
                    if (match.hasMatch()) {
                        previewEngine_->parseMessage(messageId, match.captured(1));
                    }
                }

                return;
            }

            // If the message didn't contain any links, then we can just update the UI.
            Q_EMIT messageParsed(messageId, html);
        });
}

void
MessageParser::preprocessMarkdown(QString& markdown)
{
    // Match all instances of the linefeed character, except when followed by 3 backticks.
    // static QRegularExpression newlineRegex("\n(?!```)");
    static QRegularExpression newlineRegex("\n");

    // Replace all instances of the linefeed character with 2 spaces + a linefeed character.
    markdown.replace(newlineRegex, "  \n");
}

// A callback function that will be called by the md4c library (`md_html`) to output the HTML.
static void
htmlChunkCb(const MD_CHAR* data, MD_SIZE data_size, void* userData)
{
    QByteArray* array = static_cast<QByteArray*>(userData);
    if (data_size > 0) {
        array->append(data, int(data_size));
    }
};

QString
MessageParser::markdownToHtml(const char* markdown)
{
    static auto md_flags = MD_FLAG_COLLAPSEWHITESPACE | MD_FLAG_WIKILINKS | MD_FLAG_LATEXMATHSPANS
                           | MD_FLAG_PERMISSIVEAUTOLINKS | MD_FLAG_UNDERLINE
                           | MD_FLAG_STRIKETHROUGH;
    size_t data_len = strlen(markdown);
    if (data_len <= 0) {
        return QString();
    } else {
        QByteArray array;
        int result = md_html(markdown, MD_SIZE(data_len), &htmlChunkCb, &array, md_flags, 0);
        return result == 0 ? QString::fromUtf8(array) : QString();
    }
}
