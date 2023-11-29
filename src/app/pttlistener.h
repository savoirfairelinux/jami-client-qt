#pragma once

#include "appsettingsmanager.h"

#include <QObject>
#include <QThread>
#include <QKeyEvent>

class PTTListener : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE Qt::Key getCurrentKey()
    {
        int keyInt = settingsManager_->getValue(Settings::Key::PttKeys).toInt();
        Qt::Key key = static_cast<Qt::Key>(keyInt);
        return key;
    }

    Q_INVOKABLE QString keyToString(Qt::Key key)
    {
        return QKeySequence(key).toString();
    }

    Q_INVOKABLE void setPttKey(Qt::Key key)
    {
        settingsManager_->setValue(Settings::Key::PttKeys, key);
    }
    Q_INVOKABLE bool getPttState()
    {
        return settingsManager_->getValue(Settings::Key::EnablePtt).toBool();
    }

    PTTListener(AppSettingsManager* settingsManager, QObject* parent = nullptr);
    ~PTTListener();

Q_SIGNALS:
    void pttKeyPressed();
    void pttKeyReleased();

#ifdef HAVE_GLOBAL_PTT
public Q_SLOTS:
    void startListening();
    void stopListening();
#endif

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;

    AppSettingsManager* settingsManager_;
};
