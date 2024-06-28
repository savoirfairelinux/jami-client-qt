#pragma once

// #include "appsettingsmanager.h"
#include "videoprovider.h"

#include <QCoreApplication>
#include <QObject>
#include <QThread>
#include <QKeyEvent>
#include <QTimer>

class LinkDeviceModule : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void startScanning(const QString& accountId, const QString& id);
    Q_INVOKABLE void stopScanning(const QString& accountId);

    LinkDeviceModule(QObject* parent = nullptr);
    ~LinkDeviceModule();

Q_SIGNALS:
    void peerDetected(const QString& uri, const QString& accountId);

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;
};
