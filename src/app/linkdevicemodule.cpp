#include "linkdevicemodule.h"
#include <QDebug>

#include <QImage>
#include "ReadBarcode.h"
#include <sstream>
#include "ImageView.h"

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

// on the OLD device this will start scanning for qr code
// TODO add a stop scanning
void
LinkDeviceModule::startScanning(const QString& accountId, const QString& id)
{
    qWarning() << Q_FUNC_INFO << id;

    auto videoProvider = qApp->property("VideoProvider").value<VideoProvider*>();
    auto timer = new QTimer(this);
    // TODO put timer in a map and remove it when done?
    connect(timer, &QTimer::timeout, this, [this, videoProvider, id, accountId]() {
        // check the frame
        // 1. get the frame
        // 2. flatten
        // 3. emit signal if qr valid
        auto frame = videoProvider->captureRawVideoFrame(id);
        auto flat = frame.convertToFormat(
            QImage::Format_Grayscale8); // TODO 16 for better low light performance ????

        if (!flat.isNull()) {
            // qWarning("[LinkDevice] Grayscale image.");

            const uint8_t* imageData = flat.bits();
            int width = flat.width();
            int height = flat.height();
            int rowStride = flat.bytesPerLine();

            // create ZXing ImageView
            ZXing::ImageView imageView(imageData, width, height, ZXing::ImageFormat::Lum, rowStride);

            // set up options
            auto options = ZXing::ReaderOptions()
                               .setFormats(ZXing::BarcodeFormat::MatrixCodes)
                               .setTryInvert(false)
                               .setTextMode(ZXing::TextMode::HRI)
                               .setMaxNumberOfSymbols(10);

            auto barcodes = ZXing::ReadBarcodes(imageView, options);

            for (auto& barcode : barcodes) {
                qWarning() << "[LinkDevice] Text: " << barcode.text();

                QString uri = QString::fromStdString(barcode.text());

                if (uri.contains("jami-auth://"))
                    // Q_EMIT exportToPeer(accountId, uri);
                    Q_EMIT peerDetected(uri); // will get accountId in the qml from currentaccount?
            }
        } else {
            qWarning("[LinkDevice] Error processing image in linkdevicemodule");
            // stopScannig(id)
        }
    });
    timer->start(333);
    // TODO optimize timer
}

void
LinkDeviceModule::stopScanning(const QString& id)
{
    // TODO take timer from map and remove it
}

#include "linkdevicemodule.moc"
