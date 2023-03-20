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

#include "previewengine.h"

#include "utils.h"

#include "md4c-html.h"
#include "tidy.h"
#include "tidybuffio.h"

#include <QWebEngineScript>
#include <QWebEngineProfile>
#include <QWebEngineSettings>

#include <QtWebChannel>
#include <QWebEnginePage>

class TidyHTMLParser
{
public:
    TidyHTMLParser()
    {
        // Create Tidy document object
        doc_ = tidyCreate();

        // Set options to configure how Tidy should parse the HTML file
        tidyOptSetBool(doc_, TidyQuiet, yes);
        tidyOptSetBool(doc_, TidyShowWarnings, no);
        tidyOptSetBool(doc_, TidyShowErrors, no);
    }

    ~TidyHTMLParser()
    {
        // Clean up Tidy objects
        tidyRelease(doc_);
    }

    TidyDoc* parseHTMLString(const char* input) //, std::string& output)
    {
        int rc = -1;

        // Parse the HTML string
        rc = tidyParseString(doc_, input);

        // If parsing was successful, generate output string
        if (rc >= 0) {
            //            tidySaveBuffer(doc_, &output_);
            //            output = std::string((char*) output_.bp);
            return &doc_;
        }

        return nullptr;
    }

private:
    TidyDoc doc_;
};

struct PreviewEngine::Impl : public QWebEnginePage
{
public:
    PreviewEngine& parent_;
    QWebChannel* channel_;

    Impl(PreviewEngine& parent)
        : QWebEnginePage((QObject*) nullptr)
        , parent_(parent)
    {
        QWebEngineProfile* profile = QWebEngineProfile::defaultProfile();

        QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
        dataDir.cdUp();
        auto cachePath = dataDir.absolutePath() + "/jami";
        profile->setCachePath(cachePath);
        profile->setPersistentStoragePath(cachePath);
        profile->setPersistentCookiesPolicy(QWebEngineProfile::NoPersistentCookies);
        profile->setHttpCacheType(QWebEngineProfile::NoCache);

        settings()->setAttribute(QWebEngineSettings::JavascriptEnabled, true);
        settings()->setAttribute(QWebEngineSettings::ScrollAnimatorEnabled, false);
        settings()->setAttribute(QWebEngineSettings::ErrorPageEnabled, false);
        settings()->setAttribute(QWebEngineSettings::PluginsEnabled, false);
        settings()->setAttribute(QWebEngineSettings::ScreenCaptureEnabled, false);
        settings()->setAttribute(QWebEngineSettings::LinksIncludedInFocusChain, false);
        settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, false);
        settings()->setAttribute(QWebEngineSettings::AllowRunningInsecureContent, true);
        settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls, true);
        settings()->setAttribute(QWebEngineSettings::XSSAuditingEnabled, false);
        settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessFileUrls, true);

        channel_ = new QWebChannel(this);
        channel_->registerObject(QStringLiteral("jsbridge"), &parent_);

        setWebChannel(channel_);
        runJavaScript(Utils::QByteArrayFromFile(":/linkify.js"), QWebEngineScript::MainWorld);
        runJavaScript(Utils::QByteArrayFromFile(":/linkify-string.js"), QWebEngineScript::MainWorld);
        runJavaScript(Utils::QByteArrayFromFile(":/qwebchannel.js"), QWebEngineScript::MainWorld);
        runJavaScript(Utils::QByteArrayFromFile(":/previewInfo.js"), QWebEngineScript::MainWorld);
        runJavaScript(Utils::QByteArrayFromFile(":/misc/previewInterop.js"),
                      QWebEngineScript::MainWorld);
    }

    void parseMessage(const QString& messageId, const QString& msg, bool showPreview, QColor color)
    {
        QString colorStr = "'" + color.name() + "'";
        runJavaScript(QString("parseMessage(`%1`, `%2`, %3, %4)")
                          .arg(messageId, msg, showPreview ? "true" : "false", colorStr));
    }
};

PreviewEngine::PreviewEngine(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(*this))
{}

PreviewEngine::~PreviewEngine() {}

void
traverseNode(TidyDoc* doc, TidyNode node)
{
    TidyBuffer nodeValue = {};
    if (tidyNodeGetId(node) == TidyTag_A) {
        if (tidyNodeGetText(*doc, node, &nodeValue) == yes) { // get value of p node
            qWarning() << "ANCHOR Node value:" << QString::fromLocal8Bit(nodeValue.bp);
        }
    } else if (tidyNodeGetId(node) == TidyTag_PRE) {
        if (tidyNodeGetText(*doc, node, &nodeValue) == yes) { // get value of p node
            qWarning() << "PRE Node value:" << QString::fromLocal8Bit(nodeValue.bp);
        }
    }

    for (TidyNode child = tidyGetChild(node); child; child = tidyGetNext(child)) {
        traverseNode(doc, child);
    }
}

void
preprocessMarkdown(QString& markdown)
{
    qWarning() << "MD:" << markdown;
    // Create a regular expression pattern that matches newline characters.
    static QRegularExpression newlineRegex("\n");

    // Replace all instances of the newline character with the HTML line break tag (<br>).
    markdown.replace(newlineRegex, "  \n");
    qWarning() << "MD-fixed:" << markdown;
}

void
captureHtmlFragment(const MD_CHAR* data, MD_SIZE data_size, void* userData)
{
    QByteArray* array = static_cast<QByteArray*>(userData);
    if (data_size > 0) {
        array->append(data, int(data_size));
    }
}

QString
convertMarkdownToHtml(const char* raw_data)
{
    size_t data_len = strlen(raw_data);

    if (data_len <= 0) {
        return QString();
    } else {
        QByteArray array;
        int render_result = md_html(raw_data,
                                    MD_SIZE(data_len),
                                    &captureHtmlFragment,
                                    &array,
                                    MD_DIALECT_GITHUB | MD_FLAG_WIKILINKS | MD_FLAG_LATEXMATHSPANS
                                        | MD_FLAG_PERMISSIVEATXHEADERS | MD_FLAG_UNDERLINE,
                                    0);

        if (render_result == 0) {
            TidyHTMLParser htmlParser;
            if (auto doc = htmlParser.parseHTMLString(array.constData())) {
                TidyNode node = tidyGetRoot(*doc);
                traverseNode(doc, node);
            }
            auto html = QString::fromUtf8(array);
            qWarning() << "HTML:" << html;
            return html;
        } else {
            return QString();
        }
    }
}

void
PreviewEngine::parseMessage(const QString& messageId, QString& msg, bool showPreview, QColor color)
{
    // preprocessMarkdown(msg);
    auto html = convertMarkdownToHtml(msg.toUtf8().constData());
    Q_EMIT linkified(messageId, convertMarkdownToHtml(msg.toUtf8().constData()));
    // pimpl_->parseMessage(messageId, msg, showPreview, color);
}

void
PreviewEngine::log(const QString& str)
{
    qDebug() << str;
}

void
PreviewEngine::emitInfoReady(const QString& messageId, const QVariantMap& info)
{
    Q_EMIT infoReady(messageId, info);
}

void
PreviewEngine::emitLinkified(const QString& messageId, const QString& linkifiedStr)
{
    Q_EMIT linkified(messageId, linkifiedStr);
}
