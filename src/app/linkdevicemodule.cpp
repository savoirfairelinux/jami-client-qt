/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include "linkdevicemodule.h"
#include "appsettingsmanager.h"
// #include "xcbkeyboard.h"

#include <QCoreApplication>
#include <QVariant>

// #include <X11/X.h>
// #include <X11/Xlib.h>
// #include <X11/Xutil.h>

#include <thread>

class LinkDeviceModule::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(LinkDeviceModule* parent)
        : QObject(nullptr)
        , parent_(*parent)
    // , display_(XOpenDisplay(NULL))
    // , root_(DefaultRootWindow(display_))
    {
        thread_.reset(new QThread());
        moveToThread(thread_.get());
    }

    ~Impl()
    {
        thread_->quit();
        thread_->wait();
        // stopListening();
        // XCloseDisplay(display_);
    };

private Q_SLOTS:

private:
    LinkDeviceModule& parent_;
    // Display* display_;
    // Window root_;
    QScopedPointer<QThread> thread_;
    std::atomic_bool stop_ {false};
};

void
LinkDeviceModule::startScanning(const QString& id)
{
    qWarning() << Q_FUNC_INFO << id;

    auto videoProvider = qApp->property("VideoProvider").value<VideoProvider*>();
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this, videoProvider, id]() {
        // check the frame
        // 1. get the frame
        // 2. flatten
        // 3. emit signal if qr valid

        auto frame = videoProvider->captureRawVideoFrame(id);
        auto flat = frame.convertToFormat(
            QImage::Format_Grayscale8); // TODO 16 for better low light performance ????
        if (!flat.isNull()) {
            qWarning("[LinkDevice] Grayscale image.");
        }
    });
    timer->start(250);
}

LinkDeviceModule::LinkDeviceModule(AppSettingsManager* settingsManager, QObject* parent)
    : settingsManager_(settingsManager)
    , QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

LinkDeviceModule::~LinkDeviceModule() = default;

#include "linkdevicemodule.moc"
