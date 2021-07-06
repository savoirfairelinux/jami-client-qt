#pragma once

#include "utils.h"

#include <QtWebChannel>
#include <QtWebEngine>
#include <QtWebEngineCore>
#include <QtWebEngine>
#include <QWebEngineView>

class PreviewEngine;

class PreviewEnginePrivate : public QObject
{
    Q_OBJECT
public:
    PreviewEnginePrivate(PreviewEngine* parent)
        : parent_(parent)
    {}

    Q_INVOKABLE void infoReady(int messageId, QVariantList info);
    Q_INVOKABLE void log(QString str);

private:
    PreviewEngine* parent_;
};

class PreviewEngine : public QWebEngineView
{
    Q_OBJECT

public:
    explicit PreviewEngine(QObject* parent = nullptr);
    void beginPreviewProcess(int messageId, QString url);

Q_SIGNALS:
    void emitPreviewInfo(int messageIndex, QString urlInMessage);
    void testJSEmit(int messageIndex);
    void previewIsReady(int messageId, QVariantList previewInfo);

private:
    QWebChannel* channel_;
    PreviewEnginePrivate* pimpl_;
};
