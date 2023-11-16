/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

#include "htmlparser.h"

#include <QRegularExpression>
#include <QThread>

class PreviewEngine::Parser : public QObject
{
    Q_OBJECT

public:
    explicit Parser(QObject* parent = nullptr);
    ~Parser() = default;

    Q_SIGNAL void infoReady(const QString& id, const QVariantMap& info);

public:
    Q_SLOT void processHTML(const QString& id, const QString& link, const QString& data);

private:
    // An instance of HtmlParser used to parse HTML.
    HtmlParser* htmlParser_;

    QString getTagContent(const QList<QString>& tags, const QString& value);
    QString getTitle(const QList<QString>& metaTags);
    QString getDescription(const QList<QString>& metaTags);
    QString getImage(const QList<QString>& metaTags);

    static const QRegularExpression newlineRe;
};

const QRegularExpression PreviewEngine::Parser::newlineRe("\\r?\\n");

PreviewEngine::PreviewEngine(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
    , parser_(new PreviewEngine::Parser)
{
    parserThread_ = new QThread();
    parser_->moveToThread(parserThread_);

    connect(this, &PreviewEngine::parseLink, this, &PreviewEngine::onParseLink);
    connect(this, &PreviewEngine::htmlReady, parser_.get(), &Parser::processHTML);
    connect(parser_.get(), &Parser::infoReady, this, &PreviewEngine::infoReady);

    parserThread_->start();
}

PreviewEngine::~PreviewEngine()
{
    parserThread_->quit();
    parserThread_->wait();
}

void
PreviewEngine::onParseLink(const QString& id, const QString& link)
{
    sendGetRequest(link,
                   [this, id, link](const QByteArray& html) { Q_EMIT htmlReady(id, link, html); });
}

PreviewEngine::Parser::Parser(QObject* parent)
    : QObject(parent)
    , htmlParser_(new HtmlParser(this))
{}

QString
PreviewEngine::Parser::getTagContent(const QList<QString>& tags, const QString& value)
{
    Q_FOREACH (auto tag, tags) {
        const QRegularExpression re("(property|name)=\"(og:|twitter:|)" + value
                                    + "\".*?content=\"([^\"]+)\"");
        const auto match = re.match(tag.remove(newlineRe));
        if (match.hasMatch()) {
            return match.captured(3);
        }
    }
    return QString {};
}

QString
PreviewEngine::Parser::getTitle(const QList<QString>& metaTags)
{
    // Try with opengraph/twitter props
    QString title = getTagContent(metaTags, "title");
    if (title.isEmpty()) { // Try with title tag
        title = htmlParser_->getTagInnerHtml(TidyTag_TITLE);
    }
    if (title.isEmpty()) { // Try with h1 tag
        title = htmlParser_->getTagInnerHtml(TidyTag_H1);
    }
    if (title.isEmpty()) { // Try with h2 tag
        title = htmlParser_->getTagInnerHtml(TidyTag_H2);
    }
    return title;
}

QString
PreviewEngine::Parser::getDescription(const QList<QString>& metaTags)
{
    // Try with og/twitter props
    QString desc = getTagContent(metaTags, "description");
    if (desc.isEmpty()) { // Try with first paragraph
        desc = htmlParser_->getTagInnerHtml(TidyTag_P);
    }
    return desc;
}

QString
PreviewEngine::Parser::getImage(const QList<QString>& metaTags)
{
    // Try with og/twitter props
    QString image = getTagContent(metaTags, "image");
    if (image.isEmpty()) { // Try with href of link tag (rel="image_src")
        auto tagsNodes = htmlParser_->getTagsNodes({TidyTag_LINK});
        Q_FOREACH (auto tag, tagsNodes[TidyTag_LINK]) {
            QString href = htmlParser_->getNodeAttr(tag, TidyAttr_HREF);
            if (!href.isEmpty()) {
                return href;
            }
        }
    }
    return image;
}

void
PreviewEngine::Parser::processHTML(const QString& id, const QString& link, const QString& data)
{
    htmlParser_->parseHtmlString(data);
    auto tagsNodes = htmlParser_->getTagsNodes({TidyTag_META});
    auto metaTagNodes = tagsNodes[TidyTag_META];
    QList<QString> metaTags;
    Q_FOREACH (auto tag, metaTagNodes) {
        metaTags.append(htmlParser_->getNodeText(tag));
    }
    QString domain = QUrl(link).host();
    if (domain.isEmpty()) {
        domain = link;
    }
    Q_EMIT infoReady(id,
                     {{"title", getTitle(metaTags)},
                      {"description", getDescription(metaTags)},
                      {"image", getImage(metaTags)},
                      {"url", link},
                      {"domain", domain}});
}

#include "previewengine.moc"
