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

const GLfloat verticesCorTexCor[] = {-1.0f, -1.0f, 0.0f,  0.0f, 0.0f, -1.0f, 1.0f,
                                     0.0f,  0.0f,  1.0f,  1.0f, 1.0f, 0.0f,  1.0f,
                                     1.0f,  1.0f,  -1.0f, 0.0f, 1.0f, 0.0f};

const int g_indices[] = {0, 1, 2, 2, 3, 0};

// VideoRenderingItemBase
VideoRenderingItemBase::VideoRenderingItemBase(QQuickItem* parent)
    : QQuickItem(parent)
    , renderer_(nullptr)
{
    connect(this, &QQuickItem::windowChanged, this, &VideoRenderingItemBase::handleWindowChanged);

    connect(LRCInstance::renderer(), &RenderManager::previewAvFrameUpdated, [this]() {
        // prepareFrameToDisplay(LRCInstance::renderer()->getPreviewAVFrame());
        renderer_->requestTextureUpdate();
        window()->update();
    });
    connect(LRCInstance::renderer(), &RenderManager::previewRenderingStopped, [this]() {
        // prepareFrameToDisplay(LRCInstance::renderer()->getPreviewAVFrame());
        renderer_->requestTextureUpdate();
        window()->update();
    });
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
    }
}

void
VideoRenderingItemBase::cleanup()
{
    delete renderer_;
    renderer_ = nullptr;
}

class CleanupJob : public QRunnable
{
public:
    CleanupJob(VideoRenderingItemRenderer* renderer)
        : renderer_(renderer)
    {}
    void run() override
    {
        delete renderer_;
    }

private:
    VideoRenderingItemRenderer* renderer_;
};

void
VideoRenderingItemBase::releaseResources()
{
    window()->scheduleRenderJob(new CleanupJob(renderer_), QQuickWindow::BeforeSynchronizingStage);
    renderer_ = nullptr;
}

void
VideoRenderingItemBase::sync()
{
    if (!renderer_) {
        renderer_ = new VideoRenderingItemRenderer();
        connect(window(),
                &QQuickWindow::afterRendering,
                renderer_,
                &VideoRenderingItemRenderer::paint,
                Qt::DirectConnection);
    }

    QRect viewportGeo = QRect(x(),
                              y(),
                              size().width() * window()->devicePixelRatio(),
                              size().height() * window()->devicePixelRatio());

    renderer_->setViewportGeo(viewportGeo);
    renderer_->setWindow(window());
}

void
VideoRenderingItemBase::geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry)
{
    Q_UNUSED(oldGeometry)
    if (renderer_)
        renderer_->setViewportGeo(newGeometry.toRect());
}

// VideoRenderingItemRenderer
VideoRenderingItemRenderer::VideoRenderingItemRenderer()
    : appWindow_(nullptr)
    , shaderProgram_(nullptr)
    , sizeTexture_(16, 9)
    , linesizeWidthScaleFactors_(1.0f, 1.0f, 1.0f)
{
    vbo_ = new QOpenGLBuffer(QOpenGLBuffer::VertexBuffer);
    ibo_ = new QOpenGLBuffer(QOpenGLBuffer::IndexBuffer);
    frameTex_.Ytex = new QOpenGLTexture(QOpenGLTexture::Target::Target2D);
    frameTex_.Utex = new QOpenGLTexture(QOpenGLTexture::Target::Target2D);
    frameTex_.Vtex = new QOpenGLTexture(QOpenGLTexture::Target::Target2D);
    frameTex_.UVtex_NV12 = new QOpenGLTexture(QOpenGLTexture::Target::Target2D);
}

VideoRenderingItemRenderer::~VideoRenderingItemRenderer()
{
    vbo_->destroy();
    ibo_->destroy();
    frameTex_.Ytex->destroy();
    frameTex_.Utex->destroy();
    frameTex_.Vtex->destroy();
    delete frameTex_.Ytex;
    delete frameTex_.Utex;
    delete frameTex_.Vtex;
    delete shaderProgram_;
    delete vbo_;
    delete ibo_;
    shaderProgram_ = nullptr;
}

void
VideoRenderingItemRenderer::init()
{
    if (!shaderProgram_) {
        QSGRendererInterface* rif = appWindow_->rendererInterface();
        Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL
                 || rif->graphicsApi() == QSGRendererInterface::OpenGLRhi);

        initializeOpenGLFunctions();

        glViewport(viewportGeo_.x(),
                   viewportGeo_.y(),
                   viewportGeo_.width() * appWindow_->devicePixelRatio(),
                   viewportGeo_.height() * appWindow_->devicePixelRatio());

        qDebug() << "GL Initialize";

        initializeShaderProgram();
        setUpBuffers();

        shaderProgram_->bind();

        GLuint posYtex = shaderProgram_->uniformLocation("Ytex");
        shaderProgram_->setUniformValue(posYtex, 0);
        GLuint posUtex = shaderProgram_->uniformLocation("Utex");
        shaderProgram_->setUniformValue(posUtex, 1);
        GLuint posVtex = shaderProgram_->uniformLocation("Vtex");
        shaderProgram_->setUniformValue(posVtex, 2);
        GLuint posUV_NV12tex = shaderProgram_->uniformLocation("UVtex_NV12");
        shaderProgram_->setUniformValue(posUV_NV12tex, 3);

        shaderProgram_->release();
    }
}

void
VideoRenderingItemRenderer::paint()
{
    init();

    glViewport(viewportGeo_.x(),
               viewportGeo_.y(),
               viewportGeo_.width() * appWindow_->devicePixelRatio(),
               viewportGeo_.height() * appWindow_->devicePixelRatio());
    glScissor(viewportGeo_.x(),
              viewportGeo_.y(),
              viewportGeo_.width() * appWindow_->devicePixelRatio(),
              viewportGeo_.height() * appWindow_->devicePixelRatio());
    glEnable(GL_SCISSOR_TEST);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    shaderProgram_->bind();

    GLuint m_angleToRotate = shaderProgram_->uniformLocation("aAngleToRotate");
    shaderProgram_->setUniformValue(m_angleToRotate, 180.0f + angleToRotate_);
    GLuint m_sizeOfTexture = shaderProgram_->uniformLocation("aWidthAndHeight");
    shaderProgram_->setUniformValue(m_sizeOfTexture, sizeTexture_);
    GLuint m_sizeViewPort = shaderProgram_->uniformLocation("aViewPortWidthAndHeight");
    shaderProgram_->setUniformValue(m_sizeViewPort,
                                    QVector2D((GLfloat) viewportGeo_.width(),
                                              (GLfloat) viewportGeo_.height()));
    GLuint m_widthScalingFactors = shaderProgram_->uniformLocation("vTextureCoordScalingFactors");
    shaderProgram_->setUniformValue(m_widthScalingFactors, linesizeWidthScaleFactors_);
    GLuint m_isNV12 = shaderProgram_->uniformLocation("isNV12");
    shaderProgram_->setUniformValue(m_isNV12, isNV12_);

    vbo_->bind();
    ibo_->bind();

    if (needToUpdateTexture_) {
        updateTextures(LRCInstance::renderer()->getPreviewAVFrame());
        needToUpdateTexture_ = false;
    }

    {
        QMutexLocker lock(&textureMutex_);

        if (frameTex_.Ytex && frameTex_.Ytex->isCreated() && frameTex_.Utex
            && frameTex_.Utex->isCreated() && frameTex_.Vtex && frameTex_.Vtex->isCreated()) {
            frameTex_.Ytex->bind(0);
            frameTex_.Utex->bind(1);
            frameTex_.Vtex->bind(2);
        } else if (frameTex_.Ytex && frameTex_.Ytex->isCreated() && frameTex_.UVtex_NV12
                   && frameTex_.UVtex_NV12->isCreated()) {
            frameTex_.Ytex->bind(0);
            frameTex_.UVtex_NV12->bind(3);
        }

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        if (frameTex_.Ytex && frameTex_.Ytex->isCreated() && frameTex_.Utex
            && frameTex_.Utex->isCreated() && frameTex_.Vtex && frameTex_.Vtex->isCreated()) {
            frameTex_.Ytex->release();
            frameTex_.Utex->release();
            frameTex_.Vtex->release();
        } else if (frameTex_.Ytex && frameTex_.Ytex->isCreated() && frameTex_.UVtex_NV12
                   && frameTex_.UVtex_NV12->isCreated()) {
            frameTex_.Ytex->release();
            frameTex_.UVtex_NV12->release();
        }
    }

    ibo_->release();
    vbo_->release();

    shaderProgram_->release();
}

void
VideoRenderingItemRenderer::initializeShaderProgram()
{
    if (!shaderProgram_) {
        shaderProgram_ = new QOpenGLShaderProgram();

        if (!shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Vertex, vertexShaderFile_)) {
            qFatal("Adding vertex shaders fails");
            return;
        }

        if (!shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Fragment, fragmentShaderFile_)) {
            qFatal("Adding fragment shaders fails");
            return;
        }

        if (!shaderProgram_->link())
            qFatal("linking shaders fails");
    }
}

void
VideoRenderingItemRenderer::setUpBuffers()
{
    vbo_ = new QOpenGLBuffer(QOpenGLBuffer::VertexBuffer);
    ibo_ = new QOpenGLBuffer(QOpenGLBuffer::IndexBuffer);

    shaderProgram_->bind();
    vbo_->create();
    vbo_->setUsagePattern(QOpenGLBuffer::StaticDraw);
    vbo_->bind();
    vbo_->allocate(verticesCorTexCor, sizeof(verticesCorTexCor));

    GLuint m_posAttr = shaderProgram_->attributeLocation("aPosition");
    shaderProgram_->setAttributeBuffer(m_posAttr, GL_FLOAT, 0, 3, 5 * sizeof(GLfloat));
    shaderProgram_->enableAttributeArray(m_posAttr);

    GLuint m_textureCor = shaderProgram_->attributeLocation("aTextureCoord");
    shaderProgram_->setAttributeBuffer(m_textureCor,
                                       GL_FLOAT,
                                       3 * sizeof(GLfloat),
                                       2,
                                       5 * sizeof(GLfloat));
    shaderProgram_->enableAttributeArray(m_textureCor);

    ibo_->create();
    ibo_->setUsagePattern(QOpenGLBuffer::StaticDraw);
    ibo_->bind();
    ibo_->allocate(g_indices, sizeof(g_indices));

    vbo_->release();
    ibo_->release();
    shaderProgram_->release();
}

void
VideoRenderingItemRenderer::initializeTexture(QOpenGLTexture* texture,
                                              QOpenGLTexture::TextureFormat textureFormat,
                                              QOpenGLTexture::PixelFormat pixelFormat,
                                              int width,
                                              int height,
                                              uint8_t* data)
{
    QMutexLocker lock(&textureMutex_);

    if (!texture)
        return;
    if (texture->isCreated()) {
        if ((texture->width() == width) && (texture->height() == height)) {
            goto DATASET;
        };
        texture->destroy();
    }

    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setMinificationFilter(QOpenGLTexture::Nearest);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);
    texture->setSize(width, height);
    texture->setFormat(textureFormat);
    texture->create();
    texture->allocateStorage();

DATASET:
    texture->setData(0, 0, pixelFormat, QOpenGLTexture::PixelType::UInt8, data);
}

bool
VideoRenderingItemRenderer::updateTextures(AVFrame* frame)
{
    bool result = false;
    if (!frame || !frame->width || !frame->height) {
        return false;
    }

    double rotation = 0;
    if (auto matrix = av_frame_get_side_data(frame, AV_FRAME_DATA_DISPLAYMATRIX)) {
        const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
        rotation = av_display_rotation_get(data);
    }

    angleToRotate_ = rotation;
    sizeTexture_ = QVector2D(frame->width, frame->height);

    if (frame->linesize[0] && frame->linesize[1] && frame->linesize[2]) {
        setIsNV12(false);
        if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV420P) {
            initializeTexture(frameTex_.Ytex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[0],
                              frame->height,
                              frame->data[0]);
            initializeTexture(frameTex_.Utex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[1],
                              frame->height / 2,
                              frame->data[1]);
            initializeTexture(frameTex_.Vtex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[2],
                              frame->height / 2,
                              frame->data[2]);
            linesizeWidthScaleFactors_.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            linesizeWidthScaleFactors_.setY((GLfloat) frame->width / 2
                                            / (GLfloat) frame->linesize[1]);
            linesizeWidthScaleFactors_.setZ((GLfloat) frame->width / 2
                                            / (GLfloat) frame->linesize[2]);
            result = true;
        } else if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV422P) {
            initializeTexture(frameTex_.Ytex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[0],
                              frame->height,
                              frame->data[0]);
            initializeTexture(frameTex_.Utex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[1],
                              frame->height,
                              frame->data[1]);
            initializeTexture(frameTex_.Vtex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[2],
                              frame->height,
                              frame->data[2]);
            linesizeWidthScaleFactors_.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            linesizeWidthScaleFactors_.setY((GLfloat) frame->width / 2
                                            / (GLfloat) frame->linesize[1]);
            linesizeWidthScaleFactors_.setZ((GLfloat) frame->width / 2
                                            / (GLfloat) frame->linesize[2]);
            result = true;
        } else if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
            initializeTexture(frameTex_.Ytex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[0],
                              frame->height,
                              frame->data[0]);
            initializeTexture(frameTex_.Utex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[1],
                              frame->height,
                              frame->data[1]);
            initializeTexture(frameTex_.Vtex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[2],
                              frame->height,
                              frame->data[2]);
            linesizeWidthScaleFactors_.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            linesizeWidthScaleFactors_.setY((GLfloat) frame->width / (GLfloat) frame->linesize[1]);
            linesizeWidthScaleFactors_.setZ((GLfloat) frame->width / (GLfloat) frame->linesize[2]);
            result = true;
        }
        return result;
    }

    if (frame->linesize[0] && frame->linesize[1]) {
        // the format is NV12
        if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
            initializeTexture(frameTex_.Ytex,
                              QOpenGLTexture::LuminanceFormat,
                              QOpenGLTexture::Luminance,
                              frame->linesize[0],
                              frame->height,
                              frame->data[0]);
            initializeTexture(frameTex_.UVtex_NV12,
                              QOpenGLTexture::RG8_UNorm,
                              QOpenGLTexture::RG,
                              frame->linesize[1],
                              frame->height / 2,
                              frame->data[1]);
            setIsNV12(true);
            result = true;
        }
    }

    if (frame->linesize[0] && frame->linesize[1]) {
        // all hardware accelerated formats are NV12
        // if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_CUDA) {
        //    // support the CUDA hardware accel frame
        //    result = updateTextureFromCUDA(frame);
        //} else {
        //    result = false;
        //}
        result = false;
    }

    return result;
}

void
VideoRenderingItemRenderer::setIsNV12(bool isNV12)
{
    if (isNV12 != isNV12_) {
        clearFrameTextures();
        isNV12_ = isNV12;
    }
}

void
VideoRenderingItemRenderer::clearFrameTextures()
{
    {
        QMutexLocker lock(&textureMutex_);
        if (frameTex_.Ytex && frameTex_.Ytex->isCreated()) {
            frameTex_.Ytex->destroy();
        }
        if (frameTex_.UVtex_NV12 && frameTex_.UVtex_NV12->isCreated()) {
            frameTex_.UVtex_NV12->destroy();
        }
        if (frameTex_.Utex && frameTex_.Utex->isCreated()) {
            frameTex_.Utex->destroy();
        }
        if (frameTex_.Vtex && frameTex_.Vtex->isCreated()) {
            frameTex_.Vtex->destroy();
        }
    }
}
