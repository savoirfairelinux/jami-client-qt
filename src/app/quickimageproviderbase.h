/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include <QImage>
#include <QObject>
#include <QQuickImageProvider>
#include <QThreadPool>

class LRCInstance;

class AsyncImageResponseRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    AsyncImageResponseRunnable(const QString& id, const QSize& requestedSize, LRCInstance* lrcInstance)
        : id_(id)
        , requestedSize_(requestedSize)
        , lrcInstance_(lrcInstance)
    {}

    Q_SIGNAL void done(QImage image);

protected:
    QString id_;
    QSize requestedSize_;
    LRCInstance* lrcInstance_;
};

template<typename T_Runnable>
class AsyncImageResponse : public QQuickImageResponse
{
public:
    AsyncImageResponse(const QString& id, const QSize& requestedSize, QThreadPool* pool, LRCInstance* instance)
    {
        auto runnable = new T_Runnable(id, requestedSize, instance);
        connect(runnable, &T_Runnable::done, this, &AsyncImageResponse::handleDone);
        pool->start(runnable);
    }

    void handleDone(QImage image)
    {
        image_ = image;
        Q_EMIT finished();
    }

    QQuickTextureFactory* textureFactory() const override
    {
        return QQuickTextureFactory::textureFactoryForImage(image_);
    }

    QImage image_;
};

class AsyncImageProviderBase : public QQuickAsyncImageProvider
{
public:
    AsyncImageProviderBase(LRCInstance* instance = nullptr)
        : QQuickAsyncImageProvider()
        , lrcInstance_(instance)
    {}

protected:
    LRCInstance* lrcInstance_ {nullptr};
    QThreadPool pool_;
};

class QuickImageProviderBase : public QQuickImageProvider
{
public:
    QuickImageProviderBase(QQuickImageProvider::ImageType type,
                           QQmlImageProviderBase::Flag flag,
                           LRCInstance* instance = nullptr)
        : QQuickImageProvider(type, flag)
        , lrcInstance_(instance)
    {}

protected:
    LRCInstance* lrcInstance_ {nullptr};
};
