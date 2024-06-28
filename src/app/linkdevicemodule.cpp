#include "linkdevicemodule.h"
#include <QDebug>

LinkDeviceModule::LinkDeviceModule(AppSettingsManager* settingsManager, QObject* parent)
    : QObject(parent), settingsManager_(settingsManager)
{
    // constructor implementation
}

LinkDeviceModule::~LinkDeviceModule()
{
    // destructor implementation
}

void LinkDeviceModule::startScanning(const QString& id)
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
        auto flat = frame.convertToFormat(QImage::Format_Grayscale8); // TODO 16 for better low light performance ????
        if (!flat.isNull()) {
            qWarning("[LinkDevice] Grayscale image.");
        }
    });
    timer->start(250);
}
