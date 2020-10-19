#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>
//#include <gtest/gtest.h>

#include "mainapplication.h"
#include "qmlregister.h"


#if (TEST_LEVEL == 2)

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

int main(int argc, char **argv)
{
    // Remove all "--failonwarn" from argv, as quick_test_main_with_setup() will
    // fail if given an invalid command-line argument.
    auto end = std::remove_if(argv + 1, argv + argc, [](char *argv) {
        return (strcmp(argv, "--failonwarn") == 0);
    });

    if (end != argv + argc) {
        /* With this environment variable, the first warning will stop the
         * application with a non-zero return code. Effectively failing the
         * test.
         */
        qputenv("QT_FATAL_WARNINGS", "1");

        // Adjust the argument count.
        argc = std::distance(argv, end);
    }

    QTEST_SET_MAIN_SOURCE_PATH
    Setup setup;
    return quick_test_main_with_setup(argc, argv, "qml_test", nullptr, &setup);
}

//QUICK_TEST_MAIN_WITH_SETUP(testqml, Setup)
#include "main.moc"
#endif
