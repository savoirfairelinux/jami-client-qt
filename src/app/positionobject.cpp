#include "positionobject.h"

PositionObject::PositionObject(QVariant latitude, QVariant longitude, QObject* parent)
    : QObject(parent)
    , resetTime(20000)
    , longitude_(longitude)
    , latitude_(latitude)

{
    watchdog_ = new QTimer(this);
    watchdog_->start(resetTime);
    connect(watchdog_, &QTimer::timeout, this, &PositionObject::timeout);
}

void
PositionObject::resetWatchdog()
{
    watchdog_->start(resetTime);
}

QVariant
PositionObject::getLongitude()
{
    return longitude_;
}
QVariant
PositionObject::getLatitude()
{
    return latitude_;
}
