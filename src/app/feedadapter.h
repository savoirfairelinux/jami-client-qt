/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#pragma once

#include "qmladapterbase.h"
#include "lrcinstance.h"

#include <QApplication>
#include <QQmlEngine>
#include <QTimer>
#include <QVariantList>

class FeedAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON
    Q_PROPERTY(QVariantList feeds READ feeds NOTIFY feedsChanged)
    Q_PROPERTY(QVariantList followed READ followed NOTIFY feedsChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    static FeedAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new FeedAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
    }
    explicit FeedAdapter(LRCInstance* instance, QObject* parent = nullptr);
    QVariantList feeds() const
    {
        return feeds_;
    }
    QVariantList followed() const;
    QString error() const
    {
        return error_;
    }
    Q_INVOKABLE QVariantMap details(const QString& id) const;
    Q_INVOKABLE QVariantList contacts(const QString& accountId) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clearError();
    Q_INVOKABLE QString createFeed(const QString& accountId, const QString& title, const QString& avatar, bool replies);
    Q_INVOKABLE bool update(
        const QString& accountId, const QString& id, const QString& title, const QString& avatar, bool replies);
    Q_INVOKABLE bool closeFeed(const QString& accountId, const QString& id);
    Q_INVOKABLE bool authorize(const QString& accountId, const QString& id, const QString& uri, bool allowed);
    Q_INVOKABLE bool subscribe(const QString& accountId, const QString& id, bool subscribed);
    Q_INVOKABLE void open(const QString& id);
    Q_INVOKABLE QString readAvatar(const QUrl& url);

Q_SIGNALS:
    void feedsChanged();
    void errorChanged();

private:
    void reload();
    void fail(const QString& error);
    QVariantList feeds_;
    QString error_;
    QTimer refreshTimer_;
};
