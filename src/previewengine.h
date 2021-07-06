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
    explicit PreviewEnginePrivate(PreviewEngine* parent)
        : parent_(parent)
    {}

    Q_INVOKABLE void infoReady(QString messageId, QVariantMap previewInfo);
    Q_INVOKABLE void log(QString str);

private:
    PreviewEngine* parent_;
};

class PreviewEngine : public QWebEngineView
{
    Q_OBJECT

public:
    explicit PreviewEngine(QObject* parent = nullptr);
    ~PreviewEngine() = default;

    void getPreviewInfo(QString messageId, QString url);

Q_SIGNALS:
    void infoReady(QString messageId, QVariantMap previewInfo);

private:
    QWebChannel* channel_;
    PreviewEnginePrivate* pimpl_;
};
