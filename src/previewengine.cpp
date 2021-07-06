#include "previewengine.h"

#include <QtWebEngine>
#include <QWebEngineScript>


PreviewEngine::PreviewEngine(QWidget* parent)
 : QWebEngineView(parent)
// , pimpl_(new PreviewEnginePrivate(this))
{
    pimpl_ = new PreviewEnginePrivate(this);
    channel_ = new QWebChannel(page());
    channel_->registerObject(QStringLiteral("previewJSBridge"), pimpl_);

    page()->setWebChannel(channel_);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/qwebchannel.js"), QWebEngineScript::MainWorld);
    page()->runJavaScript(Utils::QByteArrayFromFile(":/previewInfo.js"), QWebEngineScript::MainWorld);
}


void
PreviewEngine::beginPreviewProcess(int messageId, QString url)
{

    QString functionCall = QString("getPreviewInformation(%1, %2)").arg(QString(messageId), "https://youtube.com");
   // page()->runJavaScript(QString("trial('%1')").arg(url));
    page()->runJavaScript(functionCall);
}


void
PreviewEnginePrivate::printExample(QString str)
{
    qDebug() << str;
}



void PreviewEnginePrivate::previewInformationReady(int messageId, QVariantList previewInformation)
{
    qDebug() << "FIRST ELEMENT OF LIST " << previewInformation.at(0) << "\n";
    Q_EMIT parent_->previewIsReady(messageId, previewInformation);
}

