#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>

#include "mainapplication.h"
#include "qmlregister.h"

#ifdef ENABLE_TESTS

class Setup : public QObject
{
    Q_OBJECT

public:
    Setup() {}

public slots:

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        registerTypes();
        engine->addImportPath("qrc:/tests/qml");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(testqml, Setup)
#include "main.moc"
#endif
