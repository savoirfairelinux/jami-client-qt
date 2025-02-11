#include "qrcodescanner.h"

#include <Barcode.h>
#include <MultiFormatReader.h>
#include <ReadBarcode.h>
#include <ImageView.h>

#include <QDebug>

QRCodeScannerModel::QRCodeScannerModel(QObject* parent)
    : QObject(parent)
{}

QString
QRCodeScannerModel::scanImage(const QImage& image)
{
    if (image.isNull())
        return QString();

    // Convert QImage to grayscale and get raw data
    QImage grayImage = image.convertToFormat(QImage::Format_Grayscale8);
    int width = grayImage.width();
    int height = grayImage.height();

    try {
        // Create ZXing image
        ZXing::ImageView imageView(grayImage.bits(), width, height, ZXing::ImageFormat::Lum);

        // Configure reader
        ZXing::ReaderOptions options;
        options.setTryHarder(true);
        options.setTryRotate(true);
        options.setFormats(ZXing::BarcodeFormat::QRCode);

        // Try to detect QR code
        auto result = ZXing::ReadBarcode(imageView, options);

        if (result.isValid()) {
            QString text = QString::fromStdString(result.text());
            // emit qrCodeDetected(text);
            return text;
        }
    } catch (const std::exception& e) {
        qWarning() << "QR code scanning error:" << e.what();
    }

    return QString();
}
