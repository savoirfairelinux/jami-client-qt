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
    settings()->setAttribute(QWebEngineSettings::JavascriptCanOpenWindows, true);
    settings()->setAttribute(QWebEngineSettings::ScrollAnimatorEnabled, false);
    settings()->setAttribute(QWebEngineSettings::ErrorPageEnabled, false);
    settings()->setAttribute(QWebEngineSettings::PluginsEnabled, false);
    settings()->setAttribute(QWebEngineSettings::FullScreenSupportEnabled, true);
    settings()->setAttribute(QWebEngineSettings::ScreenCaptureEnabled, false);
    settings()->setAttribute(QWebEngineSettings::LinksIncludedInFocusChain, false);
    settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, false);
    settings()->setAttribute(QWebEngineSettings::AllowRunningInsecureContent, true);
    settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls, true);
    settings()->setAttribute(QWebEngineSettings::XSSAuditingEnabled, false);
    settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessFileUrls, true);

    settings()->setFontSize(QWebEngineSettings::MinimumFontSize, 2);

    setContextMenuPolicy(Qt::ContextMenuPolicy::NoContextMenu);

    channel_ = new QWebChannel(this);
    channel_->registerObject(QStringLiteral("previewJSBridge"), pimpl_);

    page()->setWebChannel(channel_);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/qwebchannel.js"),
                          QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/previewInfo.js"),
                          QWebEngineScript::MainWorld);
}

void
PreviewEngine::beginPreviewProcess(QString messageId, QString url)
{
    page()->runJavaScript(
        QString("getPreviewInfo(`%1`, `%2`)").arg(messageId, QString(url)));
}

void
PreviewEnginePrivate::log(QString str)
{
    qDebug() << str;
}

void
PreviewEnginePrivate::infoReady(QString messageId, QStringList previewInformation)
{
    QVariantMap map;

    map["title"] = previewInformation.at(0);
    map["image"] = previewInformation.at(1);
    map["description"] = previewInformation.at(2);
    map["url"] = previewInformation.at(3);

    Q_EMIT parent_->previewIsReady(messageId, map);
}
