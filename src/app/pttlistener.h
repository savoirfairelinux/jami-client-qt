#pragma once

#include <QObject>
#include <QThread>
#include <QString>

class PTTListener : public QObject
{
    Q_OBJECT

public:
    static PTTListener& getInstance()
    {
        static PTTListener instance;
        return instance;
    }

    Q_INVOKABLE bool getPttState()
    {
        return pttOn_;
    }
    Q_INVOKABLE void setPttState(bool on)
    {
        pttOn_ = on;
    }
    Q_INVOKABLE QString getKeyString();

Q_SIGNALS:
    void PTTKeyPressed();
    void PTTKeyReleased();

public Q_SLOTS:
    void startListening();
    void stopListening();

private:
    PTTListener(QObject* parent = nullptr);
    ~PTTListener();

    PTTListener(const PTTListener&) = delete;
    void operator=(const PTTListener&) = delete;
    class Impl;
    std::unique_ptr<Impl> pimpl_;
    bool pttOn_ = true;
};
