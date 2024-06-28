#include "linkdevicemodule.h"
#include <QDebug>

// #include <ZXingQtReader.h>
// #include "ZXing/ZXingQtReader.h"
#include <QImage>
#include "ReadBarcode.h"
// #include "ZXing/ReadBarcode.h"
// #include "../../3rdparty/zxing-cpp/core/src/ReadBarcode.h"

class LinkDeviceModule::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(LinkDeviceModule* parent)
        : QObject(parent)
    {}

    ~Impl() = default;
};

LinkDeviceModule::LinkDeviceModule(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

LinkDeviceModule::~LinkDeviceModule() = default;

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
            // ZXingQt::
        }
    });
    timer->start(250);
}

#include "linkdevicemodule.moc"
