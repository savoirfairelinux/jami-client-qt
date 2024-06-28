#pragma once

#include "../appsettingsmanager.h"
#include "../videoprovider.h"

#include <QCoreApplication>
#include <QObject>
#include <QThread>
#include <QTimer>

class QrScanner : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE bool getState()
    {
        return true;
        // return settingsManager_->getValue(Settings::Key::EnablePtt).toBool();
    }

    Q_INVOKABLE void startScanning(const QString& sinkId)
    {
        qWarning(id) << Q_FUNC_INFO << sinkId;
        auto videoProvider = qApp->property("VideoProvider").value<VideoProvider*>();
        auto timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, [this, videoProvider, id]() {
            // check the frame
            // 1. get the frame
            // 2. convert the frame to grayscale
            // 3. check with QR detector from the library called zxing
            // 4. if QR detected, emit the signal
            // 5. if not, do nothing
            // Let's go!
            auto frame = videoProvider->captureRawVideoFrame(id);
            auto greyFrame = frame.convertToFormat(QImage::Format_Grayscale8);
            // Now use ZXing to detect QR code
            if (!greyFrame.isNull()) {
                qWarning() << "yay gray frame!";
                // emit a linkdevice signal if jami-auth uri is detected
            }
        });
        timer->start(200);
    }

    QrScanner(AppSettingsManager* settingsManager, QObject* parent = nullptr);
    ~QrScanner();

Q_SIGNALS:
    void qrCodeFound();

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;

    AppSettingsManager* settingsManager_;
};
