/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include <QColor>
#include <QObject>

#include "md4c-html.h"

void captureHtmlFragment(const MD_CHAR* data, MD_SIZE data_size, void* userData);
QString convertMarkdownToHtml(char* raw_data);

class PreviewEngine : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(PreviewEngine)
public:
    PreviewEngine(QObject* parent = nullptr);
    ~PreviewEngine();

    void parseMessage(const QString& messageId,
                      const QString& msg,
                      bool showPreview,
                      QColor color = "#0645AD");

    Q_INVOKABLE void log(const QString& str);
    Q_INVOKABLE void emitInfoReady(const QString& messageId, const QVariantMap& info);
    Q_INVOKABLE void emitLinkified(const QString& messageId, const QString& linkifiedStr);

Q_SIGNALS:
    void infoReady(const QString& messageId, const QVariantMap& info);
    void linkified(const QString& messageId, const QString& linkifiedStr);

private:
    struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
