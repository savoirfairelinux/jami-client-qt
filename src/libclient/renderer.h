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

#pragma once

#include "api/video.h"
#include "typedefs.h"

#include <QObject>
#include <QSize>

#include <map>
#include <memory>
#include <string>
#include <vector>

namespace lrc {
namespace video {

class FpsTracker;

class Renderer : public QObject
{
    Q_OBJECT
public:
    constexpr static const char RENDERER_ID[] = "RENDERER_ID";
    constexpr static const char FPS[] = "FPS";
    constexpr static const char RES[] = "RES";

    Renderer(const QString& id, const QSize& res);
    virtual ~Renderer();

    /**
     * @return renderer's fps
     */
    double fps() const;

    /**
     * @return renderer's id
     */
    QString id() const;

    /**
     * @return current renderer dimensions
     */
    QSize size() const;

    /**
     * @return current rendered frame
     */
    virtual lrc::api::video::Frame currentFrame() const = 0;

    /**
     * set fps
     */
    void setFPS(double fps);

    /**
     * Update the FPS tracker.
     */
    void updateFpsTracker();

    MapStringString getInfos() const;

public Q_SLOTS:
    virtual void startRendering() = 0;
    virtual void stopRendering() = 0;

Q_SIGNALS:
    void frameUpdated();
    void stopped();
    void started(const QSize& size);
    void frameBufferRequested(AVFrame* avFrame);
    void fpsChanged();

private:
    QString id_;
    QSize size_;
    double fps_;

    FpsTracker* fpsTracker_;
};

// Helper that counts ticks, and notifies of FPS changes.
class FpsTracker : public QObject
{
    Q_OBJECT
public:
    FpsTracker(QObject* parent = nullptr);
    ~FpsTracker() = default;

    // Call this function every frame.
    void update();

    // Emitted after every checkInterval_ when update() is called.
    Q_SIGNAL void fpsUpdated(double fps);

private:
    using clock_type = std::chrono::high_resolution_clock;
    const double checkInterval_ {1.0};
    unsigned frameCount_ {0};
    std::chrono::time_point<clock_type> lastTime_;
};

} // namespace video
} // namespace lrc
