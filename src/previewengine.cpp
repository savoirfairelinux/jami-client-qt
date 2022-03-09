/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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

#include <QWebEngineScript>
#include <QWebEngineProfile>
#include <QWebEngineSettings>

#include <QtWebChannel>
#include <QWebEnginePage>

class PreviewEngine::Impl : public QObject
{
public:
    PreviewEngine& parent_;
    QWebEnginePage* page;
    QWebChannel* channel_;
    Impl(PreviewEngine& parent)
        : QObject(nullptr)
        , parent_(parent)
    {
        QWebEngineProfile* profile = QWebEngineProfile::defaultProfile();
        page = new QWebEnginePage(this);

        QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
        dataDir.cdUp();
        auto cachePath = dataDir.absolutePath() + "/jami";
        profile->setCachePath(cachePath);
        profile->setPersistentStoragePath(cachePath);
        profile->setPersistentCookiesPolicy(QWebEngineProfile::NoPersistentCookies);
        profile->setHttpCacheType(QWebEngineProfile::NoCache);

        page->settings()->setAttribute(QWebEngineSettings::JavascriptEnabled, true);
        page->settings()->setAttribute(QWebEngineSettings::ScrollAnimatorEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::ErrorPageEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::PluginsEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::ScreenCaptureEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::LinksIncludedInFocusChain, false);
        page->settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::AllowRunningInsecureContent, true);
        page->settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls, true);
        page->settings()->setAttribute(QWebEngineSettings::XSSAuditingEnabled, false);
        page->settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessFileUrls, true);

        channel_ = new QWebChannel(this);
        channel_->registerObject(QStringLiteral("jsbridge"), this);

        page->setWebChannel(channel_);
        page->runJavaScript(Utils::QByteArrayFromFile(":/linkify.js"), QWebEngineScript::MainWorld);
        page->runJavaScript(Utils::QByteArrayFromFile(":/linkify-string.js"),
                            QWebEngineScript::MainWorld);
        page->runJavaScript(Utils::QByteArrayFromFile(":/qwebchannel.js"),
                            QWebEngineScript::MainWorld);
        page->runJavaScript(Utils::QByteArrayFromFile(":/previewInfo.js"),
                            QWebEngineScript::MainWorld);
        page->runJavaScript(Utils::QByteArrayFromFile(":/misc/previewInterop.js"),
                            QWebEngineScript::MainWorld);
    }
    void parseMessage(const QString& messageId, const QString& msg, bool showPreview)
    {
        page->runJavaScript(QString("parseMessage(`%1`, `%2`, %3)")
                                .arg(messageId, msg, showPreview ? "true" : "false"));
    }

    void log(const QString& str)
    {
        qDebug() << str;
    }

    void infoReady(const QString& messageId, const QVariantMap& info)
    {
        Q_EMIT parent_.infoReady(messageId, info);
    }

    void linkifyReady(const QString& messageId, const QString& linkified)
    {
        Q_EMIT parent_.linkifyReady(messageId, linkified);
    }
};

PreviewEngine::PreviewEngine(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(*this))
{}

PreviewEngine::~PreviewEngine() {}

void
PreviewEngine::parseMessage(const QString& messageId, const QString& msg, bool showPreview)
{
    pimpl_->parseMessage(messageId, msg, showPreview);
}
