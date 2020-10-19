#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>

#include "mainapplication.h"
#include "qmlregister.h"


#ifdef ENABLE_TESTS

class tst_clientUI : public QObject
{
    Q_OBJECT

public:
    tst_clientUI() {}

public slots:

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        registerTypes();
        engine->addImportPath("qrc:/tests");
    }
};

QUICK_TEST_MAIN_WITH_SETUP(testqml, tst_clientUI)

#include "tst_clientui.moc"
#endif
