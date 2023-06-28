#include "imagedownloader.h"
#include <QDir>

ImageDownloader::ImageDownloader(ConnectivityMonitor* cm, QObject* parent)
    : NetworkManager(cm, parent)
{}

void
ImageDownloader::downloadImageToCache(const QUrl& url, const QString& localPath)
{
    Utils::oneShotConnect(this, &NetworkManager::errorOccured, this, [this, localPath]() {
        onDownloadImageFinished({}, localPath);
    });

    sendGetRequest(url, [this, localPath](const QByteArray& imageData) {
        onDownloadImageFinished(imageData, localPath);
    });
}

void
ImageDownloader::onDownloadImageFinished(const QByteArray& data, const QString& localPath)
{
    if (!data.isEmpty()) {
        // Check if the parent folders exist create them if not
        QString dirPath = localPath.left(localPath.lastIndexOf('/'));
        QDir dir;
        dir.mkpath(dirPath);

        QFile file(localPath);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(data);
            file.close();
            Q_EMIT downloadImageSuccessfull(localPath);
            return;
        }
    }
    Q_EMIT downloadImageFailed(localPath);
}
