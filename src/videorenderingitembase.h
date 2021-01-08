/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

#include <QtQuick>
#include <QWindow>
#include <QMutex>
#include <QMutexLocker>
#include <QOpenGLFunctions>
#include <QOpenGLTexture>
#include <QOpenGLShaderProgram>
#include <QOpenGLBuffer>

extern "C" {
// FFMPEG headers
#include <libavutil/frame.h>
#include <libavutil/display.h>
#include <libavutil/hwcontext.h>
}

struct YUVFrameTexture
{
    QOpenGLTexture* Ytex;
    QOpenGLTexture* Utex;
    QOpenGLTexture* Vtex;
    QOpenGLTexture* UVtex_NV12;
};

class VideoRenderingItemRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    explicit VideoRenderingItemRenderer();
    ~VideoRenderingItemRenderer();

    void setViewportGeo(const QRect& geo)
    {
        viewportGeo_ = geo;
    }

    void setWindow(QQuickWindow* window)
    {
        appWindow_ = window;
    }

    void requestTextureUpdate()
    {
        needToUpdateTexture_ = true;
    }

public slots:
    void init();
    void paint();

protected:
    void initializeShaderProgram();
    void setUpBuffers();

    void initializeTexture(QOpenGLTexture* texture,
                           QOpenGLTexture::TextureFormat textureFormat,
                           QOpenGLTexture::PixelFormat pixelFormat,
                           int width,
                           int height,
                           uint8_t* data);
    bool updateTextures(AVFrame* frame);

    void setIsNV12(bool isNV12);

    void clearFrameTextures();

private:
    bool needToUpdateTexture_ {false};

    QString vertexShaderFile_ {":/shader/YUVConv.vert"};
    QString fragmentShaderFile_ {":/shader/YUVConv.frag"};

    QMutex textureMutex_;

    QRect viewportGeo_;

    QOpenGLShaderProgram* shaderProgram_;
    QOpenGLBuffer* vbo_;
    QOpenGLBuffer* ibo_;
    YUVFrameTexture frameTex_;

    // uniform values to pass in the shader
    bool isNV12_ = false;
    GLfloat angleToRotate_ = 0.0f;
    QVector2D sizeTexture_;
    QVector3D linesizeWidthScaleFactors_;

    QQuickWindow* appWindow_;
};

class VideoRenderingItemBase : public QQuickItem
{
    Q_OBJECT

public:
    explicit VideoRenderingItemBase(QQuickItem* parent = 0);
    ~VideoRenderingItemBase();

public slots:
    void sync();
    void cleanup();

protected:
    void geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry);

private slots:
    void handleWindowChanged(QQuickWindow* win);

private:
    void releaseResources() override;

    VideoRenderingItemRenderer* renderer_;
};
