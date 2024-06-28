#pragma once

#include "appsettingsmanager.h"
#include "videoprovider.h"

#include <QCoreApplication>
#include <QObject>
#include <QThread>
#include <QKeyEvent>
#include <QTimer>

class LinkDeviceModule : public QObject
{
    Q_OBJECT

public:

    Q_INVOKABLE void startScanning(const QString& id)
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

    LinkDeviceModule(AppSettingsManager* settingsManager, QObject* parent = nullptr);
    // PTTListener(AppSettingsManager* settingsManager, QObject* parent = nullptr);
    ~LinkDeviceModule();
    // ~PTTListener();

Q_SIGNALS:

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;

    AppSettingsManager* settingsManager_;
};
