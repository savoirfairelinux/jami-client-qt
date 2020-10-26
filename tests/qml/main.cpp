#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>

#ifdef ENABLE_TESTS

class Setup : public QObject
{
    Q_OBJECT

public:
    Setup() {}

public slots:

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        engine->addImportPath("qrc:/tests/qml");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(testqml, Setup)
#include "main.moc"
#endif
