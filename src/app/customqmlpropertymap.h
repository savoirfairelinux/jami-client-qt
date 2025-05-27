#ifndef CUSTOMQMLPROPERTYMAP_H
#define CUSTOMQMLPROPERTYMAP_H

#include <QQmlPropertyMap>
#include <QVariant>
#include <QDebug>

class CustomQmlPropertyMap : public QQmlPropertyMap
{
    Q_OBJECT

public:
    CustomQmlPropertyMap(QObject *parent = nullptr)
        : QQmlPropertyMap(this, parent) {}

    // Set value from C++ and emit valueChanged()
    void setValue(const QString &key, const QVariant &value) {
        QVariant oldValue = QQmlPropertyMap::value(key);
        if (oldValue != value) {
            QQmlPropertyMap::insert(key, value);
            Q_EMIT valueChanged(key, value);
        }
    }
protected:
    QVariant updateValue(const QString &key, const QVariant &value) override {
        QVariant oldValue = QQmlPropertyMap::value(key);
        if (oldValue != value) {
            QQmlPropertyMap::insert(key, value);
            Q_EMIT valueChanged(key, value);
        }
        return value;
    }
Q_SIGNALS:
    void valueChanged(const QString &key, const QVariant &value);
};
#endif // CUSTOMQMLPROPERTYMAP_H
