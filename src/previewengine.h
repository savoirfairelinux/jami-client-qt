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

    Q_INVOKABLE void infoReady(const QString& messageId, const QVariantMap& info);
    Q_INVOKABLE void linkifyReady(const QString& messageId, const QString& linkified);
    Q_INVOKABLE void log(const QString& str);

private:
    PreviewEngine* parent_;
};

class PreviewEngine : public QWebEngineView
{
    Q_OBJECT
public:
    explicit PreviewEngine(QObject* parent = nullptr);
    ~PreviewEngine() = default;

    void parseMessage(const QString& messageId, const QString& msg);

Q_SIGNALS:
    void infoReady(const QString& messageId, const QVariantMap& info);
    void linkifyReady(const QString& messageId, const QString& linkified);

private:
    QWebChannel* channel_;
    PreviewEnginePrivate* pimpl_;
};
