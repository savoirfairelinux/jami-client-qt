#include "linkdevicemodule.h"
#include <QDebug>

#include <QImage>
#include "ReadBarcode.h"
#include <sstream>
// #include "ZXingQtReader.h"
// #include "../../3rdparty/zxing-cpp/example/ZXingQtReader.h"

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
            // qWarning("[LinkDevice] Grayscale image.");

            // int width = flat.width(), height = flat.height();
            // // unsigned char* data;
            // // load your image data from somewhere. ImageFormat::Lum assumes grey scale image data.

            // auto image = ZXing::ImageView(flat, width, height, ZXing::ImageFormat::Lum);
            // auto options = ZXing::ReaderOptions().setFormats(
            //     ZXing::BarcodeFormat::Any /*TODO DataMatrix*/);
            // auto barcodes = ZXing::ReadBarcodes(&image, &options);

            // for (const auto& b : barcodes) {
            //     // std::stringstream ss;
            //     qInfo() << "[LinkDevice] qr -> " << ZXing::ToString(b.format()) << ": " << b.text()
            //             << "\n";
            //     // qWarning(ss);
            // }

            auto options = ZXing::ReaderOptions()
                               .setFormats(ZXing::BarcodeFormat::MatrixCodes)
                               .setTryInvert(false)
                               .setTextMode(ZXing::TextMode::HRI)
                               .setMaxNumberOfSymbols(10);

            // auto barcodes = ZXing::ReadBarcodes(flat, options));
            // ZXing::ImageView imgCopy = ZXing_ImageView_new(flat.bits(), flat.width(), flat.height(), ZXing::ImageFormat::Lum, flat.bytesPerLine(), 0);

// ZXing_ImageView* ZXing_ImageView_new(const uint8_t* data, int width, int height, ZXing_ImageFormat format, int rowStride,
// 									 int pixStride);
            ZXing::Barcodes barcodes = ZXing::ReadBarcodes({flat.bits(), flat.width(), flat.height(), QImage::Format_Grayscale8, static_cast<int>(flat.bytesPerLine())}, options));
            // auto barcodes = ZXing::ReadBarcodes({flat.bits(), flat.width(), flat.height(), QImage::Format_Grayscale8, static_cast<int>(flat.bytesPerLine())}, options));
            // auto barcodes = ReadBarcodes(flat, options);

            for (auto& barcode : barcodes) {
                qDebug() << "[LinkDevice] qr -> ";
                qDebug() << "Text:   " << barcode.text();
                qDebug() << "Format: " << barcode.format();
                qDebug() << "Content:" << barcode.contentType();
                qDebug() << "";
            }
        }
    });
    timer->start(250);
}

#include "linkdevicemodule.moc"





// inline QList<Barcode> ReadBarcodes(const QImage& img, const ReaderOptions& opts = {})
// {
// 	using namespace ZXing;

// 	auto ImgFmtFromQImg = [](const QImage& img) {
// 		switch (img.format()) {
// 		case QImage::Format_ARGB32:
// 		case QImage::Format_RGB32:
// #if Q_BYTE_ORDER == Q_LITTLE_ENDIAN
// 			return ImageFormat::BGRA;
// #else
// 			return ImageFormat::ARGB;
// #endif
// 		case QImage::Format_RGB888: return ImageFormat::RGB;
// 		case QImage::Format_RGBX8888:
// 		case QImage::Format_RGBA8888: return ImageFormat::RGBA;
// 		case QImage::Format_Grayscale8: return ImageFormat::Lum;
// 		default: return ImageFormat::None;
// 		}
// 	};

// 	auto exec = [&](const QImage& img) {
// 		return ZXBarcodesToQBarcodes(ZXing::ReadBarcodes(
// 			{img.bits(), img.width(), img.height(), ImgFmtFromQImg(img), static_cast<int>(img.bytesPerLine())}, opts));
// 	};

// 	return ImgFmtFromQImg(img) == ImageFormat::None ? exec(img.convertToFormat(QImage::Format_Grayscale8)) : exec(img);
// }



// // TODO
// {
//     // ReaderOptions options;
//     Barcodes allBarcodes;

//     // options.setTextMode(TextMode::HRI);
//     // options.setEanAddOnSymbol(EanAddOnSymbol::Read);

//     // for (const auto& filePath : cli.filePaths) {
//     // 	int width, height, channels;
//     // 	std::unique_ptr<stbi_uc, void (*)(void*)> buffer(stbi_load(filePath.c_str(), &width,
//     &height,
//     // &channels, cli.forceChannels),
//     stbi_image_free); 	if (buffer == nullptr) { 		std::cerr << "Failed
//     // to read image: " << filePath << " (" << stbi_failure_reason() << ")" << "\n"; return -1;
//     // 	}
//     // 	channels = cli.forceChannels ? cli.forceChannels : channels;

//     // auto ImageFormatFromChannels = std::array{ImageFormat::None, ImageFormat::Lum,
//     // ImageFormat::LumA, ImageFormat::RGB, ImageFormat::RGBA};
//     ImageView image {buffer.get(), width, height, ImageFormatFromChannels.at(channels)};
//     auto barcodes = ReadBarcodes(image.rotated(cli.rotate), options);
//     // KESS take this

//     // if we did not find anything, insert a dummy to produce some output for each file
//     if (barcodes.empty())
//         barcodes.emplace_back();

//     allBarcodes.insert(allBarcodes.end(), barcodes.begin(), barcodes.end());
//     if (filePath == cli.filePaths.back()) {
//         auto merged = MergeStructuredAppendSequences(allBarcodes);
//         // report all merged sequences as part of the last file to make the logic not overly
//         // complicated here
//         barcodes.insert(barcodes.end(),
//                         std::make_move_iterator(merged.begin()),
//                         std::make_move_iterator(merged.end()));
//     }

//     for (auto&& barcode : barcodes) {
//         if (!cli.outPath.empty())
//             drawRect(image, barcode.position(), bool(barcode.error()));

//         ret |= static_cast<int>(barcode.error().type());

//         if (cli.bytesOnly) {
//             std::cout.write(reinterpret_cast<const char*>(barcode.bytes().data()),
//                             barcode.bytes().size());
//             continue;
//         }

//         if (cli.oneLine) {
//             std::cout << filePath << " " << ToString(barcode.format());
//             if (barcode.isValid())
//                 std::cout << " \"" << barcode.text(TextMode::Escaped) << "\"";
//             else if (barcode.error())
//                 std::cout << " " << ToString(barcode.error());
//             std::cout << "\n";
//             continue;
//         }

//         if (cli.filePaths.size() > 1 || barcodes.size() > 1) {
//             static bool firstFile = true;
//             if (!firstFile)
//                 std::cout << "\n";
//             if (cli.filePaths.size() > 1)
//                 std::cout << "File:       " << filePath << "\n";
//             firstFile = false;
//         }

//         if (barcode.format() == BarcodeFormat::None) {
//             std::cout << "No barcode found\n";
//             continue;
//         }

//         // std::cout << "Text:       \"" << barcode.text() << "\"\n"
//         // 		  << "Bytes:      " << ToHex(options.textMode() == TextMode::ECI ?
//         // barcode.bytesECI() : barcode.bytes()) << "\n"
//         // 		  << "Format:     " << ToString(barcode.format()) << "\n"
//         // 		  << "Identifier: " << barcode.symbologyIdentifier() << "\n"
//         // 		  << "Content:    " << ToString(barcode.contentType()) << "\n"
//         // 		  << "HasECI:     " << barcode.hasECI() << "\n"
//         // 		  << "Position:   " << ToString(barcode.position()) << "\n"
//         // 		  << "Rotation:   " << barcode.orientation() << " deg\n"
//         // 		  << "IsMirrored: " << barcode.isMirrored() << "\n"
//         // 		  << "IsInverted: " << barcode.isInverted() << "\n";

//         // printOptional("EC Level:   ", barcode.ecLevel());
//         // printOptional("Version:    ", barcode.version());
//         // printOptional("Error:      ", ToString(barcode.error()));

//         // if (barcode.lineCount())
//         // 	std::cout << "Lines:      " << barcode.lineCount() << "\n";
//     }
