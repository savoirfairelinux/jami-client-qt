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

    LinkDeviceModule(QObject* parent = nullptr);
    ~LinkDeviceModule();

Q_SIGNALS:
    void exportToPeer(const QString& accountId, const QString& uri);

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;
};
