#ifndef PREVIEWENGINE_H
#define PREVIEWENGINE_H

#pragma once


#include <QObject>
#include <QtWebChannel>
#include <QtWebEngine>
#include <QtWebEngineCore>
#include <QtWebEngine>

#include <QWebEngineView>

#include "utils.h"
class PreviewEngine;

class PreviewEnginePrivate : public QObject
{

    Q_OBJECT
public:
    PreviewEnginePrivate(PreviewEngine* parent) : parent_(parent){}

    PreviewEngine* parent_;

    Q_INVOKABLE void previewInformationReady(int messageId, QVariantList previewInformation);
    Q_INVOKABLE void printExample(QString str);


};



class PreviewEngine : public QWebEngineView
{

    Q_OBJECT


public:
    explicit PreviewEngine(QWidget* parent = nullptr);

    void beginPreviewProcess(int messageId, QString url);

Q_SIGNALS:
    void emitPreviewInfo(int messageIndex, QString urlInMessage);

    void testJSEmit(int messageIndex);

    void previewIsReady(int messageId, QVariantList previewInfo);



private:
    QWebChannel* channel_;
    PreviewEnginePrivate* pimpl_;
};






#endif // PREVIEWENGINE_H




