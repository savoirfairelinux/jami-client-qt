/*
 *  Copyright (C) 2018-2024 Savoir-faire Linux Inc.
 *  Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

#include "renderer.h"

#include <QSize>
#include <QMutex>

// Uncomment following line to output in console the FPS value for the
// current renderer type (DirectRenderer, ShmRenderer, etc.).
// #define DEBUG_FPS

namespace lrc {
namespace video {

using namespace lrc::api::video;

Renderer::Renderer(const QString& id, const QSize& res)
    : QObject(nullptr)
    , id_(id)
    , size_(res)
    , fps_(0.0)
    , fpsTracker_(new FpsTracker(this))
{
    // Subscribe to frame rate updates.
    connect(fpsTracker_, &FpsTracker::fpsUpdated, this, [this](double fps) {
        setFPS(fps);
#ifdef DEBUG_FPS
        qDebug() << this << ": FPS " << fps;
#endif
    });
}

Renderer::~Renderer() {}

double
Renderer::fps() const
{
    return fps_;
}

QString
Renderer::id() const
{
    return id_;
}

QSize
Renderer::size() const
{
    return size_;
}
void
Renderer::setFPS(double fps)
{
    fps_ = fps;
    Q_EMIT fpsChanged();
}

void
Renderer::updateFpsTracker()
{
    fpsTracker_->update();
}

MapStringString
Renderer::getInfos() const
{
    MapStringString map;
    map[RENDERER_ID] = id();
    map[FPS] = QString::number(fps());
    map[RES] = QString::number(size().width()) + " * " + QString::number(size().height());
    return map;
}

FpsTracker::FpsTracker(QObject* parent)
    : QObject(parent)
    , lastTime_(clock_type::now())
{}

void
FpsTracker::update()
{
    frameCount_++;
    auto now = clock_type::now();
    const std::chrono::duration<double> elapsed = now - lastTime_;
    if (elapsed.count() >= checkInterval_) {
        double fps = static_cast<double>(frameCount_) / elapsed.count();
        Q_EMIT fpsUpdated(fps);
        frameCount_ = 0;
        lastTime_ = now;
    }
}

} // namespace video
} // namespace lrc
