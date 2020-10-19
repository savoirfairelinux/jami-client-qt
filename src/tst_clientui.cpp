#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>

#include "mainapplication.h"
#include "qmlregister.h"


#ifdef TEST_QML

class tst_clientUI : public QObject
{
    Q_OBJECT

public:
    tst_clientUI() {}

public slots:

    void qmlEngineAvailable(QQmlEngine *engine)
    {

        //char *argv[] = {"jami-qt", NULL};
        //int argc = 1;//sizeof(argv) / sizeof(char*) - 1;
        //MainApplication app(argc, &argv[0]);

        //app.init();
        registerTypes();



        //engine->rootContext()->setContextProperty("myContextProperty", QVariant(true));
    }
};

QUICK_TEST_MAIN_WITH_SETUP(testqml, tst_clientUI)

#include "tst_clientui.moc"
#endif
