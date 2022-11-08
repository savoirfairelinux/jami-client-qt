#pragma once

#include "qvariant.h"
#include <QObject>
#include <QString>
#include <QTimer>
#include <QDebug>

class PositionObject : public QObject
{
    Q_OBJECT

public:
    PositionObject(QVariant latitude, QVariant longitude, QObject* parent = nullptr);

    Q_SIGNAL void timeout();

    void resetWatchdog();

    QVariant getLongitude();
    QVariant getLatitude();

private:
    QVariant latitude_;
    QVariant longitude_;
    int resetTime;
    QTimer* watchdog_;
};
