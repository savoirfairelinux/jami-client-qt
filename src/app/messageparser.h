/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#pragma once

#include <QObject>
#include <QColor>
#include <QThreadPool>

class PreviewEngine;
class HtmlParser;

// This class is used to parse messages and encapsulate the logic that
// prepares a message for display in the UI. The basic steps are:
// 1. preprocess the markdown message (e.g. handle line breaks)
// 2. transform markdown syntax into HTML
// 3. generate previews for the first link in the message (if any)
// 4. add the appropriate CSS classes to the HTML (e.g. for links, code blocks, etc.)
//
// Step 3. is done asynchronously, so the message is displayed as soon as possible
// and the preview is added later.
class MessageParser final : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(MessageParser)
public:
    // Create a new MessageParser instance. We take an instance of PreviewEngine.
    explicit MessageParser(PreviewEngine* previewEngine, QObject* parent = nullptr);
    ~MessageParser() = default;

    // Parse the message. This will emit the messageParsed signal when the
    // message is ready to be displayed.
    void parseMessage(const QString& messageId,
                      const QString& msg,
                      bool previewLinks,
                      const QColor& linkColor,
                      const QColor& backgroundColor);

    // Emitted when the message is ready to be displayed.
    Q_SIGNAL void messageParsed(const QString& msgId, const QString& msg);

    // Emitted when the message preview is ready to be displayed.
    Q_SIGNAL void linkInfoReady(const QString& msgId, const QVariantMap& info);

private:
    // Preprocess the markdown message (e.g. handle line breaks).
    void preprocessMarkdown(QString& markdown);

    // Transform markdown syntax into HTML.
    QString markdownToHtml(const char* markdown);

    // Generate a preview for the given link, then emit the messageParsed signal.
    void generatePreview(const QString& msgId, const QString& link);

    // The PreviewEngine instance used to generate previews.
    PreviewEngine* previewEngine_;

    // An instance of HtmlParser used to parse HTML.
    HtmlParser* htmlParser_;

    // Used to queue parse operations.
    QThreadPool* threadPool_;
};
