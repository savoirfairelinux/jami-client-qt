/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "instancemanager.h"

#include "mainapplication.h"

#include <QCryptographicHash>
#include <QLocalSocket>
#include <QLocalServer>
#include <QSharedMemory>
#include <QSystemSemaphore>

static QString
generateKeyHash(const QString& key, const QString& salt)
{
    QByteArray data;
    data.append(key.toUtf8());
    data.append(salt.toUtf8());
    data = QCryptographicHash::hash(data, QCryptographicHash::Sha1).toHex();
    return data;
}

class InstanceManager::Impl : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(Impl)
public:
    Impl(const QString& key, MainApplication* mainApp)
        : QObject(nullptr)
        , mainAppInstance_(mainApp)
        , key_(key)
        , memLockKey_(generateKeyHash(key, "_memLockKey"))
        , sharedmemKey_(generateKeyHash(key, "_sharedmemKey"))
        , sharedMem_(sharedmemKey_)
        , memLock_(memLockKey_, 1)
    {}
    ~Impl() = default;

    bool tryToRun(const QByteArray& startUri)
    {
        if (isAnotherRunning()) {
            // This is a secondary instance, connect to the primary
            // instance to trigger a restore then die.
            if (connectToLocal()) {
                // Okay we connected. Send the start uri if not empty.
                if (startUri.size()) {
                    qDebug() << "Sending start URI to secondary instance." << startUri;
                    socket_->write(startUri);
                    socket_->waitForBytesWritten();
                }

                // Now this instance can die.
                return false;
            }
            // If not connected, this means that the server doesn't exist
            // and the app can be relaunched (can be the case after a client crash or Ctrl+C)
        }

        memLock_.acquire();
        const bool result = sharedMem_.create(sizeof(quint64));
        memLock_.release();
        if (!result) {
            release();
            return false;
        }

        // This is the primary instance,
        // listen for subsequent instances.
        QLocalServer::removeServer(key_);
        server_ = new QLocalServer();
        server_->setSocketOptions(QLocalServer::UserAccessOption);
        server_->listen(key_);
        QObject::connect(server_,
                         &QLocalServer::newConnection,
                         this,
                         &Impl::handleIncomingConnection);

        return true;
    };

    void tryToKill()
    {
        if (!isAnotherRunning()) {
            return;
        }

        // This is a secondary instance, connect to the primary
        // instance to trigger a termination then fail.
        if (!connectToLocal()) {
            return;
        }

        socket_->write(terminateSeq_);
        socket_->waitForBytesWritten();
    };

    void release()
    {
        memLock_.acquire();
        if (sharedMem_.isAttached())
            sharedMem_.detach();
        memLock_.release();
    };

private Q_SLOTS:
    bool connectToLocal()
    {
        if (!socket_)
            socket_ = new QLocalSocket();
        if (!socket_)
            return false;
        if (socket_->state() == QLocalSocket::UnconnectedState
            || socket_->state() == QLocalSocket::ClosingState) {
            socket_->connectToServer(key_);
        }
        if (socket_->state() == QLocalSocket::ConnectingState) {
            socket_->waitForConnected(connectionTimeoutMs_);
        }
        return socket_->state() == QLocalSocket::ConnectedState;
    }

    void handleIncomingConnection()
    {
        connection_ = new QLocalSocket(this);
        connection_ = server_->nextPendingConnection();
        connect(connection_, &QLocalSocket::readyRead, this, [this] {
            QLocalSocket* clientSocket = (QLocalSocket*) sender();
            QByteArray recievedData;
            recievedData = clientSocket->readAll();
            if (recievedData == terminateSeq_) {
                qWarning() << "Received terminate signal.";
                mainAppInstance_->quit();
            } else {
                qDebug() << "Received start URI:" << recievedData;
                auto startUri = QString::fromLatin1(recievedData);
                mainAppInstance_->handleUriAction(startUri);
            }
        });

        // Restore primary instance
        qDebug() << "Received wake-up from secondary instance.";
        mainAppInstance_->restoreApp();
    };

private:
    MainApplication* mainAppInstance_;

    const QString key_;
    const QString memLockKey_;
    const QString sharedmemKey_;

    QSharedMemory sharedMem_;
    QSystemSemaphore memLock_;

    QLocalSocket* socket_ {nullptr};
    QLocalServer* server_ {nullptr};
    QLocalSocket* connection_ {nullptr};

    const int connectionTimeoutMs_ {2000};
    const QByteArray terminateSeq_ {QByteArrayLiteral("\xde\xad\xbe\xef")};

    bool isAnotherRunning()
    {
        if (sharedMem_.isAttached())
            return false;

        memLock_.acquire();
        const bool isRunning = sharedMem_.attach();
        if (isRunning)
            sharedMem_.detach();
        memLock_.release();

        return isRunning;
    };
};

#ifdef Q_OS_MACOS
InstanceManager::InstanceManager(MainApplication* mainApp)
    : QObject(mainApp)
{}

InstanceManager::~InstanceManager() {}

bool
InstanceManager::tryToRun(const QByteArray& startUri)
{
    return true;
}

void
InstanceManager::tryToKill()
{}
#else
InstanceManager::InstanceManager(MainApplication* mainApp)
    : QObject(mainApp)
{
    QCryptographicHash appData(QCryptographicHash::Sha256);
    appData.addData(QApplication::applicationName().toUtf8());
    appData.addData(QApplication::organizationDomain().toUtf8());
    pimpl_ = std::make_unique<Impl>(appData.result(), mainApp);
}

InstanceManager::~InstanceManager()
{
    pimpl_->release();
}

bool
InstanceManager::tryToRun(const QByteArray& startUri)
{
    return pimpl_->tryToRun(startUri);
}

void
InstanceManager::tryToKill()
{
    pimpl_->tryToKill();
}
#endif

#include "moc_instancemanager.cpp"
#include "instancemanager.moc"
