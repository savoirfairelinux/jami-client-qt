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

#include <QRegularExpression>
#include <QtConcurrent>

#include "md4c-html.h"

MessageParser::MessageParser(PreviewEngine* previewEngine, QObject* parent)
    : QObject(parent)
    , previewEngine_(previewEngine)
{
    connect(previewEngine_, &PreviewEngine::infoReady, this, &MessageParser::linkInfoReady);
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

            // In order for pre/code blocks to be rendered i bit better, we need to prepend a CSS
            // style block to the HTML that will set the background color of the pre/code blocks to
            // a light grey and set wrap to true.
            html.prepend(QString("<style>pre,code{background-color:%1;"
                                 "white-space:pre-wrap;}</style>")
                             .arg("#f0f0f0"));
            // The text color of the pre/code blocks should be almost black.
            html.prepend(QString("<style>pre,code{color:%1;}</style>").arg("#222222"));

            // First check if the message contains any links. If so, we can:
            // 1. add some CSS to color them.
            // 2. parse them to get a preview IF the user has enabled link previews.
            auto link = getFirstLink(html);
            if (link.isValid()) {
                // Prepend the html with a CSS style block to color any anchors in the message.
                html.prepend(QString("<style>a{color:%1;}</style>").arg(linkColor.name()));
                // Update the UI before we start parsing the link.
                Q_EMIT messageParsed(messageId, html);

                // If the user has enabled link previews, then we need to generate the link preview.
                if (previewLinks) {
                    previewEngine_->parseMessage(messageId, link.toString());
                }
            } else {
                // If the message doesn't contain any links, then we can just update the UI.
                Q_EMIT messageParsed(messageId, html);
            }
        });
}

void
MessageParser::preprocessMarkdown(QString& markdown)
{
    static QRegularExpression newlineRegex("\n");

    // Replace all instances of the newline character with 2 spaces and a newline character.
    markdown.replace(newlineRegex, "  \n");
}

// A callback function that will be called by the md4c library to output the HTML.
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
    static auto md_flags = MD_DIALECT_GITHUB | MD_FLAG_WIKILINKS | MD_FLAG_LATEXMATHSPANS
                           | MD_FLAG_PERMISSIVEATXHEADERS | MD_FLAG_UNDERLINE;
    size_t data_len = strlen(markdown);
    if (data_len <= 0) {
        return QString();
    } else {
        QByteArray array;
        int result = md_html(markdown, MD_SIZE(data_len), &htmlChunkCb, &array, md_flags, 0);
        return result == 0 ? QString::fromUtf8(array) : QString();
    }
}

QVariant
MessageParser::getFirstLink(const QString& html)
{
    static QRegularExpression linkRegex("((http|https|ftp)://[\\w\\d:#@%/;$()~_?\\+-=\\\\.&]*)");

    auto match = linkRegex.match(html);
    if (match.hasMatch()) {
        return match.captured(1);
    } else {
        return QVariant();
    }
}
