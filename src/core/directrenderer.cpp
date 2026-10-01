/*
 *  Copyright (C) 2012-2026 Savoir-faire Linux Inc.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "directrenderer.h"

#include "dbus/videomanager.h"
#include "videomanager_interface.h"

#include <QMutex>

namespace lrc {
namespace video {

using namespace lrc::api::video;

struct DirectRenderer::Impl : public QObject
{
    Q_OBJECT
public:
    struct CallbackState
    {
        explicit CallbackState(DirectRenderer* renderer)
            : parent(renderer)
        {}

        libjami::FrameBuffer pull()
        {
            QMutexLocker lk(&mutex);
            if (!parent)
                return {};
            if (!frameBufferPtr)
                frameBufferPtr.reset(av_frame_alloc());

            // The sink needs the client-owned buffer description synchronously.
            Q_EMIT parent->frameBufferRequested(frameBufferPtr.get());
            if (frameBufferPtr->format == AV_PIX_FMT_NONE)
                return {};

            return std::move(frameBufferPtr);
        }

        void push(libjami::FrameBuffer buf)
        {
            QMutexLocker lk(&mutex);
            if (!parent)
                return;

            frameBufferPtr = std::move(buf);
            parent->updateFpsTracker();
            Q_EMIT parent->frameUpdated();
        }

        DirectRenderer* parent;
        QMutex mutex;
        libjami::FrameBuffer frameBufferPtr;
    };

    Impl(DirectRenderer* parent)
        : QObject(nullptr)
        , parent_(parent)
        , state_(std::make_shared<CallbackState>(parent))
    {
        configureTarget();
        if (!VideoManager::instance().registerSinkTarget(parent_->id(), target))
            qWarning() << "Cannot register " << parent_->id();
    };
    ~Impl()
    {
        {
            QMutexLocker lk(&state_->mutex);
            state_->parent = nullptr;
        }
        parent_->stopRendering();
        VideoManager::instance().registerSinkTarget(parent_->id(), {});
    }

    void configureTarget()
    {
        std::weak_ptr<CallbackState> state = state_;
        target.pull = [state] {
            if (auto shared = state.lock())
                return shared->pull();
            return libjami::FrameBuffer {};
        };
        target.push = [state](libjami::FrameBuffer buf) {
            if (auto shared = state.lock())
                shared->push(std::move(buf));
        };
    };

private:
    DirectRenderer* parent_;
    std::shared_ptr<CallbackState> state_;

public:
    libjami::SinkTarget target;
    FpsTracker fpsTracker;
};

DirectRenderer::DirectRenderer(const QString& id, const QSize& res)
    : Renderer(id, res)
    , pimpl_(std::make_unique<DirectRenderer::Impl>(this))
{}

DirectRenderer::~DirectRenderer() {}

void
DirectRenderer::startRendering()
{
    Q_EMIT started(size());
}

void
DirectRenderer::stopRendering()
{
    Q_EMIT stopped();
}

Frame
DirectRenderer::currentFrame() const
{
    return {};
}

} // namespace video
} // namespace lrc

#include "moc_directrenderer.cpp"
#include "directrenderer.moc"
