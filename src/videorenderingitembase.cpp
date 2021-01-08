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

#include <QOpenGLFramebufferObject>

#ifndef COMPILE_ONLY
extern "C" {
#include "libavcodec/avcodec.h"
#include "libavdevice/avdevice.h"
#include "libavformat/avformat.h"
#include "libavutil/frame.h"
#include "libswscale/swscale.h"
#include "libavutil/display.h"
#include "libavutil/hwcontext.h"
}
#else
extern "C" {
void av_frame_free(AVFrame** frame);
}
#endif

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

// VideoRenderingItemBaseRenderer
class VideoRenderingItemBaseRenderer : public QQuickFramebufferObject::Renderer
{
public:
    VideoRenderingItemBaseRenderer() {}

    void synchronize(QQuickFramebufferObject* item) override
    {
        VideoRenderingItemBase* i = static_cast<VideoRenderingItemBase*>(item);

        // Set up TexturesRenderer
        if (!render_)
            render_ = std::make_unique<TexturesRenderer>(i->getRenderingType());

        // Clear frame when needed
        if (i->getRenderingFinished()) {
            i->setRenderingFinished(false);
            return;
        }

        // Set distant rendering id
        if (!i->getDistantRenderId().isEmpty())
            render_->setDistantRenderId(i->getDistantRenderId());

        // Pass window pointer
        render_->setWindow(i->window());

        // Update frame when needed
        if (i->getNeedToUpdateFrame()) {
            if (!lrcRendererFrameMutexTryLock(i->getLrcInstance(),
                                              i->getRenderingType(),
                                              i->getDistantRenderId()))
                return;

            render_->updateFrame(i->getLrcInstance());

            // Start to process data
            render_->processData();

            lrcRendererFrameMutexUnLock(i->getLrcInstance(),
                                        i->getRenderingType(),
                                        i->getDistantRenderId());
        }

        // Pass initialized value into VideoRenderingItemBase
        i->setAngleRotated(render_->getAngleRotated());
        i->setCurrentTextureSize(render_->getTextureSize());

        i->setNeedToUpdateFrame(false);
    }

    void render() override
    {
        render_->paint();
    }

    QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override
    {
        QOpenGLFramebufferObjectFormat format;
        format.setSamples(4);
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        return new QOpenGLFramebufferObject(size, format);
    }

    bool lrcRendererFrameMutexTryLock(LRCInstance* lrcInstance,
                                      VideoRenderingItemBase::Type renderType,
                                      const QString& distantRenderId)
    {
        if (renderType == VideoRenderingItemBase::Type::PREVIEW
            || renderType == VideoRenderingItemBase::Type::PHOTO) {
            return lrcInstance->renderer()->requestPreviewFrameMutexTryLock();
        } else {
            return lrcInstance->renderer()->requestDistantFrameMutexTryLock(distantRenderId);
        }
    }

    void lrcRendererFrameMutexUnLock(LRCInstance* lrcInstance,
                                     VideoRenderingItemBase::Type renderType,
                                     const QString& distantRenderId)
    {
        if (renderType == VideoRenderingItemBase::Type::PREVIEW
            || renderType == VideoRenderingItemBase::Type::PHOTO)
            lrcInstance->renderer()->requestPreviewFrameMutexUnLock();
        else
            lrcInstance->renderer()->requestDistantFrameMutexUnLock(distantRenderId);
    }

private:
    std::unique_ptr<TexturesRenderer> render_ = nullptr;
};

// VideoRenderingItemBase
VideoRenderingItemBase::VideoRenderingItemBase(QQuickItem* parent)
    : QQuickFramebufferObject(parent)
{
    // Only items which specify QQuickItem::ItemHasContents
    // are allowed to call QQuickItem::update().
    setFlag(QQuickItem::ItemHasContents);

    connect(this, &VideoRenderingItemBase::lrcInstanceChanged, [this] {
        if (lrcInstance_)
            setRenderingType(renderingType_);
    });
}

void
VideoRenderingItemBase::takePhoto()
{
    disconnectRenderManager();

    photo_ = grabToImage(size().toSize());

    connect(photo_.get(), &QQuickItemGrabResult::ready, [this] {
        connectRenderManager();

        emit photoIsReady(Utils::byteArrayToBase64String(Utils::QImageToByteArray(photo_->image())));

        photo_.reset(nullptr);
    });
}

void
VideoRenderingItemBase::recalculateItemSize()
{
    if (currentTextureSize_.isEmpty() || renderingType_ == VideoRenderingItemBase::Type::PHOTO) {
        QQmlProperty::write(this, "width", expectedSize_.width());
        QQmlProperty::write(this, "height", expectedSize_.height());

        return;
    }

    if ((fmod(angleRotated_, 360.0) >= 45.0 && fmod(angleRotated_, 360.0) <= 135.0)
        || (fmod(angleRotated_, 360.0) >= 225.0 && fmod(angleRotated_, 360.0) <= 315.0)) {
        currentTextureSize_.transpose();
    }

    // Calculate the final size
    auto scaledSize = currentTextureSize_.scaled(expectedSize_.width(),
                                                 expectedSize_.height(),
                                                 Qt::KeepAspectRatio);

    QQmlProperty::write(this, "width", scaledSize.width());
    QQmlProperty::write(this, "height", scaledSize.height());

    emit updateParticipantsInfoRequest();
}

QQuickFramebufferObject::Renderer*
VideoRenderingItemBase::createRenderer() const
{
    return new VideoRenderingItemBaseRenderer;
}

void
VideoRenderingItemBase::connectRenderManager()
{
    if (renderingType_ == VideoRenderingItemBase::Type::PREVIEW
        || renderingType_ == VideoRenderingItemBase::Type::PHOTO) {
        connections_.updated = connect(lrcInstance_->renderer(),
                                       &RenderManager::previewAvFrameUpdated,
                                       [this]() {
                                           if (isVisible()) {
                                               setNeedToUpdateFrame(true);
                                               update();
                                           }
                                       });

        connect(lrcInstance_->renderer(), &RenderManager::previewRenderingStopped, [this]() {
            setRenderingFinished(true);
        });
    } else {
        connections_.updated = connect(lrcInstance_->renderer(),
                                       &RenderManager::distantAVFrameUpdated,
                                       [this](const QString& id) {
                                           if (distantRenderId_ == id && isVisible()) {
                                               setNeedToUpdateFrame(true);
                                               update();
                                           }
                                       });

        connect(lrcInstance_->renderer(),
                &RenderManager::distantRenderingStopped,
                [this](const QString& id) {
                    if (distantRenderId_ == id) {
                        setRenderingFinished(true);
                    }
                });
    }
}

void
VideoRenderingItemBase::disconnectRenderManager()
{
    disconnect(connections_.stopped);
    disconnect(connections_.updated);
}

// Setters
void
VideoRenderingItemBase::setRenderingType(VideoRenderingItemBase::Type type)
{
    renderingType_ = type;

    disconnectRenderManager();

    connectRenderManager();
}

void
VideoRenderingItemBase ::setNeedToUpdateFrame(bool update)
{
    needToUpdateFrame_ = update;
}

void
VideoRenderingItemBase::setDistantRenderId(QString distantRenderId)
{
    if (distantRenderId_ != distantRenderId) {
        distantRenderId_ = distantRenderId;

        emit distantRenderIdChanged();

        update();
    }
}

void
VideoRenderingItemBase::setExpectedSize(QSize newSize)
{
    if (expectedSize_ != newSize) {
        expectedSize_ = newSize;

        recalculateItemSize();

        emit expectedSizeChanged();
    }
}

void
VideoRenderingItemBase::setCurrentTextureSize(const QSize& size)
{
    if (currentTextureSize_ != size) {
        currentTextureSize_ = size;

        recalculateItemSize();

        emit currentTextureSizeChanged();
    }
}

void
VideoRenderingItemBase::setRenderingFinished(bool finished)
{
    renderingFinished_ = finished;
}

void
VideoRenderingItemBase::setAngleRotated(double angle)
{
    if (angleRotated_ != angle) {
        angleRotated_ = angle;

        recalculateItemSize();
    }
}

// Getters
bool
VideoRenderingItemBase::getNeedToUpdateFrame()
{
    return needToUpdateFrame_;
}

VideoRenderingItemBase::Type
VideoRenderingItemBase::getRenderingType()
{
    return renderingType_;
}

QString
VideoRenderingItemBase::getDistantRenderId()
{
    return distantRenderId_;
}

QSize
VideoRenderingItemBase::getExpectedSize()
{
    return expectedSize_;
}

bool
VideoRenderingItemBase::getRenderingFinished()
{
    return renderingFinished_;
}

LRCInstance*
VideoRenderingItemBase::getLrcInstance()
{
    return lrcInstance_;
}

float
VideoRenderingItemBase::getWidthScaleFactor()
{
    return static_cast<float>(width()) / static_cast<float>(currentTextureSize_.width());
}

float
VideoRenderingItemBase::getHeightScaleFactor()
{
    return static_cast<float>(height()) / static_cast<float>(currentTextureSize_.height());
}

// TexturesRenderer
TexturesRenderer::TexturesRenderer(VideoRenderingItemBase::Type type)
    : renderType_(type)
    , frame_(nullptr)
    , Ytex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , Utex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , Vtex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , UVtex_NV12_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
{
    initializeTextureDataYUV(Ytex_.get());
    initializeTextureDataYUV(Utex_.get());
    initializeTextureDataYUV(Vtex_.get());

    initializeTextureDataNV12(UVtex_NV12_.get());
}

TexturesRenderer::~TexturesRenderer()
{
    clearTextures();
}

void
TexturesRenderer::processData()
{
    initializeShaderProgram();
    processAllTexturesData();
}

void
TexturesRenderer::initializeShaderProgram()
{
    if (!shaderProgram_) {
        // Init shader
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

        // Bind shader
        shaderProgram_->bind();

        // Set up shader variable ids
        angleToRotateZId_ = shaderProgram_->uniformLocation("yawAngle");
        angleToRotateYId_ = shaderProgram_->uniformLocation("pitchAngle");
        scaleFactorId_ = shaderProgram_->uniformLocation("aScaleFactor");
        lineSizeWidthScaleFactorsId_ = shaderProgram_->uniformLocation(
            "vTextureCoordScalingFactors");
        isNV12Id_ = shaderProgram_->uniformLocation("isNV12");

        uniformTextureSampler2DIds_[0] = shaderProgram_->uniformLocation("Ytex");
        uniformTextureSampler2DIds_[1] = shaderProgram_->uniformLocation("Utex");
        uniformTextureSampler2DIds_[2] = shaderProgram_->uniformLocation("Vtex");
        uniformTextureSampler2DIds_[3] = shaderProgram_->uniformLocation("UVtex_NV12");

        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[0], 0);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[1], 1);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[2], 2);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[3], 3);

        vertsLocation_ = shaderProgram_->attributeLocation("aPosition");
        textureLocation_ = shaderProgram_->attributeLocation("aTextureCoord");

        // Unbind shader
        shaderProgram_->release();
    }
}

void
TexturesRenderer::initializeTextureDataYUV(QOpenGLTexture* texture)
{
    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setMinificationFilter(QOpenGLTexture::Nearest);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);
    texture->setFormat(QOpenGLTexture::LuminanceFormat);

    texture->create();
}

void
TexturesRenderer::initializeTextureDataNV12(QOpenGLTexture* texture)
{
    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setMinificationFilter(QOpenGLTexture::Nearest);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);
    texture->setFormat(QOpenGLTexture::LuminanceAlphaFormat);

    texture->create();
}

#ifndef COMPILE_ONLY
void
TexturesRenderer::processAllTexturesData()
{
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);

    if (frameIsEmpty()) {
        return;
    }

    if (renderType_ == VideoRenderingItemBase::Type::DISTANT) {
        angleToRotateZ_ = 180.0;
        angleToRotateY_ = 180.0;
        if (auto matrix = av_frame_get_side_data(frame_, AV_FRAME_DATA_DISPLAYMATRIX)) {
            const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
            auto angle = av_display_rotation_get(data);
            angleToRotateZ_ = angle != 0 ? angleToRotateZ_ + angle : angleToRotateZ_;
        }
    } else {
        angleToRotateZ_ = 180.0;
        angleToRotateY_ = 0.0;
    }

    textureSize_ = QSize(frame_->width, frame_->height);
    if (renderType_ == VideoRenderingItemBase::Type::PHOTO) {
        if (textureSize_.width() > textureSize_.height())
            scaleFactor_ = QVector2D(static_cast<float>(textureSize_.width())
                                         / static_cast<float>(textureSize_.height()),
                                     1);
        else
            scaleFactor_ = QVector2D(1,
                                     static_cast<float>(textureSize_.height())
                                         / static_cast<float>(textureSize_.width()));
    }

    if (frame_->linesize[0] && frame_->linesize[1] && frame_->linesize[2]) {
        isNV12_ = false;

        if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
            || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV422P
            || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
            // Y
            processTextureDataYUV(Ytex_.get(), frame_->linesize[0], frame_->height, frame_->data[0]);
            // U
            processTextureDataYUV(Utex_.get(),
                                  frame_->linesize[1],
                                  (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                       ? 0.5
                                       : 1)
                                      * frame_->height,
                                  frame_->data[1]);
            // V
            processTextureDataYUV(Vtex_.get(),
                                  frame_->linesize[2],
                                  (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                       ? 0.5
                                       : 1)
                                      * frame_->height,
                                  frame_->data[2]);

            lineSizeWidthScaleFactors_.setX((GLfloat) frame_->width / (GLfloat) frame_->linesize[0]);
            lineSizeWidthScaleFactors_.setY(
                (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[1]));
            lineSizeWidthScaleFactors_.setZ(
                (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[2]));
        }
    }

    if (frame_->linesize[0] && frame_->linesize[1]) {
        // the format is NV12
        if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
            isNV12_ = true;
            processTextureDataYUV(Ytex_.get(), frame_->linesize[0], frame_->height, frame_->data[0]);

            processTextureDataNV12(UVtex_NV12_.get(),
                                   frame_->linesize[1] / 2,
                                   frame_->height / 2,
                                   frame_->data[1]);
        }
    }
}

bool
TexturesRenderer::frameIsEmpty()
{
    return (!frame_ || !frame_->width || !frame_->height);
}
#else
void
TexturesRenderer::initializeAllTextures()
{}

bool
TexturesRenderer::frameIsEmpty()
{
    return false;
}
#endif

void
TexturesRenderer::paint()
{
    if (!shaderProgram_)
        return;

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Make sure that textures are initialized when rendering
    if (!Ytex_->isCreated()) {
        window_->resetOpenGLState();
        return;
    }

    shaderProgram_->bind();

    shaderProgram_->setUniformValue(angleToRotateZId_, static_cast<float>(angleToRotateZ_));
    shaderProgram_->setUniformValue(angleToRotateYId_, static_cast<float>(angleToRotateY_));
    shaderProgram_->setUniformValue(scaleFactorId_, scaleFactor_);
    shaderProgram_->setUniformValue(lineSizeWidthScaleFactorsId_, lineSizeWidthScaleFactors_);
    shaderProgram_->setUniformValue(isNV12Id_, isNV12_);

    shaderProgram_->enableAttributeArray(vertsLocation_);
    shaderProgram_->enableAttributeArray(textureLocation_);

    shaderProgram_->setAttributeArray(vertsLocation_, GL_FLOAT, vertexVertices, 2);
    shaderProgram_->setAttributeArray(textureLocation_, GL_FLOAT, textureVertices, 2);

    bindTextures();

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    releaseTextures();

    shaderProgram_->disableAttributeArray(textureLocation_);
    shaderProgram_->disableAttributeArray(vertsLocation_);

    shaderProgram_->release();

    window_->resetOpenGLState();
}

void
TexturesRenderer::updateFrame(LRCInstance* lrcInstance)
{
    if (renderType_ == VideoRenderingItemBase::Type::PREVIEW
        || renderType_ == VideoRenderingItemBase::Type::PHOTO)
        frame_ = lrcInstance->renderer()->getPreviewAVFrame();
    else
        frame_ = lrcInstance->renderer()->getAVFrame(distantRenderId_);
}

void
TexturesRenderer::processTextureDataYUV(QOpenGLTexture* texture,
                                        int width,
                                        int height,
                                        uint8_t* data)
{
    if (texture->width() != width && texture->height() != height) {
        texture->setSize(width, height);
        texture->allocateStorage(QOpenGLTexture::Luminance, QOpenGLTexture::PixelType::UInt8);
    }

    texture->setData(0, 0, QOpenGLTexture::Luminance, QOpenGLTexture::PixelType::UInt8, data);
}

void
TexturesRenderer::processTextureDataNV12(QOpenGLTexture* texture,
                                         int width,
                                         int height,
                                         uint8_t* data)
{
    if (texture->width() != width && texture->height() != height) {
        texture->setSize(width, height);
        texture->allocateStorage(QOpenGLTexture::LuminanceAlpha, QOpenGLTexture::PixelType::UInt8);
    }

    texture->setData(0, 0, QOpenGLTexture::LuminanceAlpha, QOpenGLTexture::PixelType::UInt8, data);
}

void
TexturesRenderer::bindTextures()
{
    Ytex_->bind(0);

    if (isNV12_) {
        UVtex_NV12_->bind(3);
    } else {
        Utex_->bind(1);

        Vtex_->bind(2);
    }
}

void
TexturesRenderer::releaseTextures()
{
    Ytex_->release();

    if (isNV12_) {
        UVtex_NV12_->release();
    } else {
        Utex_->release();

        Vtex_->release();
    }
}

void
TexturesRenderer::clearTextures()
{
    if (Ytex_ && Ytex_->isCreated()) {
        Ytex_->destroy();
    }
    if (Utex_ && Utex_->isCreated()) {
        Utex_->destroy();
    }
    if (Vtex_ && Vtex_->isCreated()) {
        Vtex_->destroy();
    }
    if (UVtex_NV12_ && UVtex_NV12_->isCreated()) {
        UVtex_NV12_->destroy();
    }
}
