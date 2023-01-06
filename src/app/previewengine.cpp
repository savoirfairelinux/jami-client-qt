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

#include <QWebEngineScript>
#include <QWebEngineProfile>
#include <QWebEngineSettings>

#include <QtWebChannel>
#include <QWebEnginePage>

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
PreviewEngine::parseMessage(const QString& messageId,
                            const QString& msg,
                            bool showPreview,
                            QColor color)
{
    pimpl_->parseMessage(messageId, msg, showPreview, color);
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
