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

class TexturesRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    explicit TexturesRenderer();
    ~TexturesRenderer();

    void setViewportSize(const QSize& size)
    {
        viewportSize_ = size;
    }

    void setWindow(QQuickWindow* window)
    {
        window_ = window;
    }

    void setItemGeo(QRect itemGeo)
    {
        itemGeo_ = itemGeo;
    }

    void updateFrame();

public slots:
    void paint();

private:
    void initializeTextureYUV(GLuint textureId, int width, int height, uint8_t* data);
    void initializeTextureNV12(GLuint textureId, int width, int height, uint8_t* data);

    QMutex drawMutex_;

    std::unique_ptr<QOpenGLShaderProgram> shaderProgram_ = nullptr;
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> frame_;

    QSize viewportSize_ {0, 0};
    QRect itemGeo_ {0, 0, 0, 0};
    QQuickWindow* window_ = nullptr;

    GLuint textureIds_[4] = {0};
    GLuint uniformTextureSampler2DIds_[4] = {0};

    QString vertexShaderFile_ {":/shader/YUVConv.vert"};
    QString fragmentShaderFile_ {":/shader/YUVConv.frag"};

    // uniform values ids to pass in the shader
    int isNV12Id_ {0};
    int angleToRotateId_ {0};
    int lineSizeWidthScaleFactorsId_ {0};

    // attribute values ids
    int vertsLocation_ {0};
    int textureLocation_ {0};
};

class VideoRenderingItemBase : public QQuickItem
{
    Q_OBJECT
public:
    explicit VideoRenderingItemBase(QQuickItem* parent = 0);
    ~VideoRenderingItemBase();

private slots:
    void handleWindowChanged(QQuickWindow* win);

signals:

public slots:
    void sync();
    void cleanup();

private slots:
    void onXChanged();
    void onYChanged();
    void onWidthChanged();
    void onHeightChanged();

private:
    TexturesRenderer* renderer_ = nullptr;
};
