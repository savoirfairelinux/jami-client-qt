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

class CircleAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON
    Q_PROPERTY(QVariantList circles READ circles NOTIFY circlesChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    static CircleAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new CircleAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
    }
    explicit CircleAdapter(LRCInstance* instance, QObject* parent = nullptr);

    QVariantList circles() const
    {
        return circles_;
    }
    QString error() const
    {
        return error_;
    }

    Q_INVOKABLE QVariantMap details(const QString& circleId) const;
    Q_INVOKABLE QVariantList contacts(const QString& accountId) const;
    Q_INVOKABLE QVariantList groups(const QString& accountId) const;
    Q_INVOKABLE void clearError();
    Q_INVOKABLE void reload();
    Q_INVOKABLE QString createCircle(const QString& accountId, const QString& name);
    Q_INVOKABLE bool renameCircle(const QString& accountId, const QString& circleId, const QString& name);
    Q_INVOKABLE bool deleteCircle(const QString& accountId, const QString& circleId);
    Q_INVOKABLE bool setMember(
        const QString& accountId, const QString& circleId, const QString& uri, bool isGroup, bool included);
    Q_INVOKABLE int broadcastText(const QString& accountId, const QString& circleId, const QString& text);

Q_SIGNALS:
    void circlesChanged();
    void errorChanged();

private:
    void fail(const QString& err);
    QVariantList circles_;
    QString error_;
    QTimer reloadTimer_;
};
