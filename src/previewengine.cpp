#include "previewengine.h"

#include <QtWebEngine>
#include <QWebEngineScript>
#include <QWebEngineProfile>
#include <QWebEngineSettings>

PreviewEngine::PreviewEngine(QObject* parent)
    : QWebEngineView(qobject_cast<QWidget*>(parent))
    , pimpl_(new PreviewEnginePrivate(this))
{
    QWebEngineProfile* profile = QWebEngineProfile::defaultProfile();

    QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
    dataDir.cdUp();
    auto cachePath = dataDir.absolutePath() + "/jami";
    profile->setCachePath(cachePath);
    profile->setPersistentStoragePath(cachePath);
    profile->setPersistentCookiesPolicy(QWebEngineProfile::NoPersistentCookies);
    profile->setHttpCacheType(QWebEngineProfile::NoCache);

    setPage(new QWebEnginePage(profile, this));

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

    setContextMenuPolicy(Qt::ContextMenuPolicy::NoContextMenu);

    channel_ = new QWebChannel(this);
    channel_->registerObject(QStringLiteral("jsbridge"), pimpl_);

    page()->setWebChannel(channel_);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/linkify.js"), QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/linkify-string.js"),
                          QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/qwebchannel.js"),
                          QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/previewInfo.js"),
                          QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/misc/previewInterop.js"),
                          QWebEngineScript::MainWorld);
}

void
PreviewEngine::parseMessage(const QString& messageId, const QString& msg)
{
    page()->runJavaScript(QString("parseMessage(`%1`, `%2`)").arg(messageId, msg));
}

void
PreviewEnginePrivate::log(const QString& str)
{
    qDebug() << str;
}

void
PreviewEnginePrivate::infoReady(const QString& messageId, const QVariantMap& info)
{
    Q_EMIT parent_->infoReady(messageId, info);
}

void
PreviewEnginePrivate::linkifyReady(const QString& messageId, const QString& linkified)
{
    Q_EMIT parent_->linkifyReady(messageId, linkified);
}
