/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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

#include "qrcodescannermodel.h"

#include <Barcode.h>
#include <MultiFormatReader.h>
#include <ReadBarcode.h>

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
            return text;
        }
    } catch (const std::exception& e) {
        qWarning() << "QR code scanning error:" << e.what();
    }

    return QString();
}
