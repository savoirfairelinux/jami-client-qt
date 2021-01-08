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

#include "videorenderingitembase.h"

#include "lrcinstance.h"

// clang-format off

static const GLfloat vertexVertices[] = {
	-1.0f, -1.0f,
	 1.0f, -1.0f,
	 -1.0f, 1.0f,
	 1.0f, 1.0f,
};

static const GLfloat textureVertices[] = {
	0.0f,  1.0f,
	1.0f,  1.0f,
	0.0f,  0.0f,
	1.0f,  0.0f,
};

// clang-format on

// VideoRenderingItemBase
VideoRenderingItemBase::VideoRenderingItemBase(QQuickItem* parent)
    : QQuickItem(parent)
{
    connect(this, &QQuickItem::windowChanged, this, &VideoRenderingItemBase::handleWindowChanged);

    connect(this, &VideoRenderingItemBase::xChanged, this, &VideoRenderingItemBase::onXChanged);
    connect(this, &VideoRenderingItemBase::yChanged, this, &VideoRenderingItemBase::onYChanged);
    connect(this,
            &VideoRenderingItemBase::widthChanged,
            this,
            &VideoRenderingItemBase::onWidthChanged);
    connect(this,
            &VideoRenderingItemBase::heightChanged,
            this,
            &VideoRenderingItemBase::onHeightChanged);
}

VideoRenderingItemBase::~VideoRenderingItemBase() {}

void
VideoRenderingItemBase::handleWindowChanged(QQuickWindow* win)
{
    if (win) {
        connect(win,
                &QQuickWindow::beforeSynchronizing,
                this,
                &VideoRenderingItemBase::sync,
                Qt::DirectConnection);
        connect(win,
                &QQuickWindow::sceneGraphInvalidated,
                this,
                &VideoRenderingItemBase::cleanup,
                Qt::DirectConnection);

        win->setClearBeforeRendering(false);
    }
}

void
VideoRenderingItemBase::sync()
{
    if (!renderer_) {
        renderer_ = new TexturesRenderer();
        connect(window(),
                &QQuickWindow::afterRendering,
                renderer_,
                &TexturesRenderer::paint,
                Qt::DirectConnection);

        connect(LRCInstance::renderer(), &RenderManager::previewAvFrameUpdated, [this]() {
            renderer_->updateFrame();
            window()->update();
        });
        connect(LRCInstance::renderer(), &RenderManager::previewRenderingStopped, [this]() {
            renderer_->updateFrame();
            window()->update();
        });
    }

    renderer_->setViewportSize(window()->size() * window()->devicePixelRatio());
    renderer_->setItemGeo(QRect(x(), y(), width(), height()));
    renderer_->setWindow(window());
}

void
VideoRenderingItemBase::cleanup()
{
    if (renderer_) {
        delete renderer_;
        renderer_ = nullptr;
    }
}

void
VideoRenderingItemBase::onXChanged()
{
    if (renderer_) {
        renderer_->setItemGeo(QRect(x(), y(), width(), height()));
        if (window())
            window()->update();
    }
}

void
VideoRenderingItemBase::onYChanged()
{
    if (renderer_) {
        renderer_->setItemGeo(QRect(x(), y(), width(), height()));
        if (window())
            window()->update();
    }
}

void
VideoRenderingItemBase::onWidthChanged()
{
    if (renderer_) {
        renderer_->setItemGeo(QRect(x(), y(), width(), height()));
        if (window())
            window()->update();
    }
}

void
VideoRenderingItemBase::onHeightChanged()
{
    if (renderer_) {
        renderer_->setItemGeo(QRect(x(), y(), width(), height()));
        if (window())
            window()->update();
    }
}

TexturesRenderer::TexturesRenderer()
    : frame_ {nullptr, [](AVFrame* frame) {
                  av_frame_free(&frame);
              }}
{}

TexturesRenderer::~TexturesRenderer() {}

void
TexturesRenderer::paint()
{
    if (!shaderProgram_) {
        initializeOpenGLFunctions();

        shaderProgram_ = std::make_unique<QOpenGLShaderProgram>();
        bool vertexShaderFileLoaded = shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Vertex,
                                                                              vertexShaderFile_);
        bool fragmentShaderFileLoaded
            = shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Fragment, fragmentShaderFile_);

        if (!vertexShaderFileLoaded || !fragmentShaderFileLoaded) {
            qDebug() << "Shader loaded failed!";
            return;
        }

        shaderProgram_->link();
    }

    bool isNV12 {false};
    QVector3D lineSizeWidthScaleFactors {1.0, 1.0, 1.0};
    double angleToRotate {0.0};
    QSize textureSize;

    shaderProgram_->bind();

    angleToRotateId_ = shaderProgram_->uniformLocation("aAngleToRotate");
    lineSizeWidthScaleFactorsId_ = shaderProgram_->uniformLocation("vTextureCoordScalingFactors");
    isNV12Id_ = shaderProgram_->uniformLocation("isNV12");

    uniformTextureSampler2DIds_[0] = shaderProgram_->uniformLocation("Ytex");
    uniformTextureSampler2DIds_[1] = shaderProgram_->uniformLocation("Utex");
    uniformTextureSampler2DIds_[2] = shaderProgram_->uniformLocation("Vtex");
    uniformTextureSampler2DIds_[3] = shaderProgram_->uniformLocation("UVtex_NV12");

    vertsLocation_ = shaderProgram_->attributeLocation("aPosition");
    textureLocation_ = shaderProgram_->attributeLocation("aTextureCoord");

    shaderProgram_->enableAttributeArray(vertsLocation_);
    shaderProgram_->enableAttributeArray(textureLocation_);

    shaderProgram_->setAttributeArray(vertsLocation_, GL_FLOAT, vertexVertices, 2);
    shaderProgram_->setAttributeArray(textureLocation_, GL_FLOAT, textureVertices, 2);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(4, textureIds_);

    // if ((fmod(angleToRotate, 360.0) >= 45.0 && fmod(angleToRotate, 360.0) <= 135.0)
    //    || (fmod(angleToRotate, 360.0) >= 225.0 && fmod(angleToRotate, 360.0) <= 315.0)) {
    //    textureSize.setWidth(frame->height);
    //    textureSize.setHeight(frame->width);
    //} else {
    //    textureSize = QSize(frame->width, frame->height);
    //}

    // float dPictureAspectRatio = (float) textureSize.width() / (float) textureSize.height();
    // float dAspectRatio = (float) width() / (float) height();

    // if (dPictureAspectRatio > dAspectRatio) {
    //    setHeight(width() * textureSize.height() / textureSize.width());
    //} else if (dPictureAspectRatio < dAspectRatio) {
    //    setWidth(height() * textureSize.width() / textureSize.height());
    //}

    {
        QMutexLocker locker(&drawMutex_);

        if (!frame_ || !frame_->width || !frame_->height) {
            return;
        }

        if (auto matrix = av_frame_get_side_data(frame_.get(), AV_FRAME_DATA_DISPLAYMATRIX)) {
            const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
            angleToRotate = av_display_rotation_get(data);
        }

        if (frame_->linesize[0] && frame_->linesize[1] && frame_->linesize[2]) {
            isNV12 = false;

            if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV422P
                || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
                // Y
                initializeTextureYUV(textureIds_[0],
                                     frame_->linesize[0],
                                     frame_->height,
                                     frame_->data[0]);
                // U
                initializeTextureYUV(textureIds_[1],
                                     frame_->linesize[1],
                                     (AVPixelFormat(frame_->format)
                                              == AVPixelFormat::AV_PIX_FMT_YUV420P
                                          ? 0.5
                                          : 1)
                                         * frame_->height,
                                     frame_->data[1]);
                // V
                initializeTextureYUV(textureIds_[2],
                                     frame_->linesize[2],
                                     (AVPixelFormat(frame_->format)
                                              == AVPixelFormat::AV_PIX_FMT_YUV420P
                                          ? 0.5
                                          : 1)
                                         * frame_->height,
                                     frame_->data[2]);

                lineSizeWidthScaleFactors.setX((GLfloat) frame_->width
                                               / (GLfloat) frame_->linesize[0]);
                lineSizeWidthScaleFactors.setY(
                    (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                    * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[1]));
                lineSizeWidthScaleFactors.setZ(
                    (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                    * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[2]));
            }
        }

        if (frame_->linesize[0] && frame_->linesize[1]) {
            // the format is NV12
            if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
                isNV12 = true;
                initializeTextureYUV(textureIds_[0],
                                     frame_->linesize[0],
                                     frame_->height,
                                     frame_->data[0]);
                initializeTextureNV12(textureIds_[3],
                                      frame_->linesize[1],
                                      frame_->height / 2,
                                      frame_->data[1]);
            }
        }
    }

    glViewport(itemGeo_.x(),
               viewportSize_.height() - itemGeo_.y() - itemGeo_.height(),
               itemGeo_.width(),
               itemGeo_.height());

    shaderProgram_->setUniformValue(angleToRotateId_, (float) angleToRotate);
    shaderProgram_->setUniformValue(lineSizeWidthScaleFactorsId_, lineSizeWidthScaleFactors);
    shaderProgram_->setUniformValue(isNV12Id_, isNV12);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureIds_[0]);
    shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[0], 0);

    if (isNV12) {
        glActiveTexture(GL_TEXTURE0 + 1);
        glBindTexture(GL_TEXTURE_2D, textureIds_[3]);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[3], 1);
    } else {
        glActiveTexture(GL_TEXTURE0 + 1);
        glBindTexture(GL_TEXTURE_2D, textureIds_[1]);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[1], 1);

        glActiveTexture(GL_TEXTURE0 + 2);
        glBindTexture(GL_TEXTURE_2D, textureIds_[2]);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[2], 2);
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindTexture(GL_TEXTURE_2D, 0);
    glDeleteTextures(4, textureIds_);

    shaderProgram_->disableAttributeArray(textureLocation_);
    shaderProgram_->disableAttributeArray(vertsLocation_);
    shaderProgram_->release();

    // Not strictly needed for this example, but generally useful for when
    // mixing with raw OpenGL.
    window_->resetOpenGLState();
}

void
TexturesRenderer::updateFrame()
{
    if (drawMutex_.tryLock()) {
        frame_.reset(LRCInstance::renderer()->getPreviewAVFrame());
        drawMutex_.unlock();
    }
}

void
TexturesRenderer::initializeTextureYUV(GLuint textureId, int width, int height, uint8_t* data)
{
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 width,
                 height,
                 0,
                 GL_LUMINANCE,
                 GL_UNSIGNED_BYTE,
                 data);
}

void
TexturesRenderer::initializeTextureNV12(GLuint textureId, int width, int height, uint8_t* data)
{
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG8, width, height, 0, GL_RG, GL_UNSIGNED_BYTE, data);
}
