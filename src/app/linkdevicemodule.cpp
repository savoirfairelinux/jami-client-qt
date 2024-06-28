#include "linkdevicemodule.h"
#include <QDebug>

#include "api/accountmodel.h"

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

    // ~Impl() = default;

    ~Impl() {
        // Ensure all timers are cleaned up
        for (auto timer : timers_) {
            if (timer) {
                timer->stop();
                timer->deleteLater();
            }
        }
        timers_.clear();
    }

    QMap<QString, QTimer*> timers_;
};

LinkDeviceModule::LinkDeviceModule(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

LinkDeviceModule::~LinkDeviceModule() = default;

// on the OLD device this will start scanning for qr code
// TODO add a stop scanning
void
LinkDeviceModule::startScanning(const QString& accountId, const QString& rendererId)
{
    // the account id is used for assigning unique timers and the renderer id is used for specifying which camera device to use
    qWarning() << Q_FUNC_INFO << rendererId;
    qWarning() << Q_FUNC_INFO << accountId;

    auto videoProvider = qApp->property("VideoProvider").value<VideoProvider*>();
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this, videoProvider, rendererId, accountId]() {
        qWarning("[LinkDevice] connected.");
        // check the frame
        // 1. get the frame
        // 2. flatten
        // 3. emit signal if qr valid
        auto frame = videoProvider->captureRawVideoFrame(rendererId);
        auto flat = frame.convertToFormat(
            QImage::Format_Grayscale8);

        if (!flat.isNull()) {
            qWarning("[LinkDevice] Grayscale image.");

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
                    Q_EMIT peerDetected(uri, accountId);
            }
        } else {
            qWarning("[LinkDevice] Error processing image in linkdevicemodule");
            // stopScanning(accountId);
        }
    });
    timer->start(333);
    // Store the timer in a map so it can be stopped later
    // auto timerTaken = pimpl_->timers_.value(accountId, nullptr);
    // if (timerTaken)
    stopScanning(accountId);
    pimpl_->timers_.insert(accountId, timer);
    // TODO optimize timer
}

void
LinkDeviceModule::stopScanning(const QString& accountId)
{
    // shutdown the timer for the given accountId and delete it if it exists
    auto timer = pimpl_->timers_.value(accountId, nullptr);
    if (timer) {
        timer->stop();
        timer->deleteLater();
        pimpl_->timers_.remove(accountId);
        qWarning() << Q_FUNC_INFO << accountId << " - Stopped scanning.";
    } else {
        qWarning() << Q_FUNC_INFO << accountId << " - No active scanning found.";
    }
}

#include "linkdevicemodule.moc"
