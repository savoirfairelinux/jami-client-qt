#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "CoreService.h"
#include "AccountListModel.h"
#include "ConversationListModel.h"
#include "MessageListModel.h"
#include "../libclient/typedefs.h"

#include <QTimer>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    qRegisterMetaType<SwarmMessage>("SwarmMessage");
    qRegisterMetaType<VectorSwarmMessage>("VectorSwarmMessage");
    qRegisterMetaType<MapStringString>("MapStringString");
    qRegisterMetaType<VectorMapStringString>("VectorMapStringString");

    // Auto-quit for testing purposes (comment out in production)
    // QTimer::singleShot(5000, &app, &QCoreApplication::quit);

    app.setOrganizationName("Savoir-faire Linux");
    app.setOrganizationDomain("savoirfairelinux.com");
    app.setApplicationName("Jami Modern");

    qDebug() << "Starting Jami Modern Client (Modern Architecture)...";

    // Initialize backend
    auto& service = CoreService::instance();
    service.setParent(&app); // Ensure destruction before app exit
    service.start();

    QQmlApplicationEngine engine;

    // Register Types
    qmlRegisterSingletonInstance("Jami.Modern", 1, 0, "CoreService", &CoreService::instance());
    qmlRegisterType<AccountListModel>("Jami.Modern", 1, 0, "AccountListModel");
    qmlRegisterType<ConversationListModel>("Jami.Modern", 1, 0, "ConversationListModel");
    qmlRegisterType<MessageListModel>("Jami.Modern", 1, 0, "MessageListModel");

    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML.";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
