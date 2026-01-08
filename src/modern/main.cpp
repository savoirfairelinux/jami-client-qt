#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QDirIterator>
#include <QTimer>

#include "CoreService.h"
#include "AccountListModel.h"
#include "ConversationListModel.h"
#include "MessageListModel.h"
#include "../libclient/typedefs.h"

int
main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    // Debug: List resources to find the correct path
    qDebug() << "Listing Root Resources:";
    QDirIterator it(":", QDirIterator::Subdirectories);
    while (it.hasNext()) {
        qDebug() << it.next();
    }

    qRegisterMetaType<SwarmMessage>("SwarmMessage");
    qRegisterMetaType<VectorSwarmMessage>("VectorSwarmMessage");
    qRegisterMetaType<MapStringString>("MapStringString");
    qRegisterMetaType<VectorMapStringString>("VectorMapStringString");

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
    // Note: CoreService is manually registered as a singleton instance because it is managed by C++
    // qmlRegisterSingletonInstance("Jami.Modern", 1, 0, "CoreService", &CoreService::instance());

    // Add root resource path to import paths to find Jami/Modern/qmldir if it is at :/Jami/Modern
    engine.addImportPath(":/");
    engine.addImportPath("qrc:/");

    // Try loading from the determined path based on qmldir inspection
    // If prefer is :/Jami/Modern/, Main.qml should be there.
    const QUrl url(QStringLiteral("qrc:/Jami/Modern/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load QML.";
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
