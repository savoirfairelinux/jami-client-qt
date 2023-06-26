#pragma once

#include "networkmanager.h"
#include "qtutils.h"

class ImageDownloader : public NetworkManager
{
    Q_OBJECT

    QML_PROPERTY(QString, cachePath)

public:
    explicit ImageDownloader(ConnectivityMonitor* cm, QObject* parent = nullptr);

    Q_INVOKABLE void downloadImageToCache(const QUrl& url, const QString& localPath);

    Q_SIGNALS:
        void downloadImageSuccessfull(const QString& localPath);
        void downloadImageFailed(const QString& localPath);

private Q_SLOTS:
    void onDownloadImageFinished(const QByteArray& reply, const QString& localPath);

private:
    QString localPath;
};