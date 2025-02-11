#pragma once

#include <QObject>
#include <QString>
#include <QImage>

#include <QQmlEngine>   // QML registration

class QRCodeScannerModel : public QObject
{
    Q_OBJECT

public:
    static QRCodeScannerModel* create(QQmlEngine*, QJSEngine*)
    {
        return new QRCodeScannerModel();
    }
    explicit QRCodeScannerModel(QObject* parent = nullptr);
    Q_INVOKABLE QString scanImage(const QImage& image);
};
