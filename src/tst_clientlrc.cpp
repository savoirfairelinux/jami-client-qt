#include <QtCore/QString>
#include <QtTest>
#include <QQmlEngine>
#include <QQmlContext>
#include <QLineEdit>

#include "mainapplication.h"

#ifdef TEST_CPP
class tst_ClientLRC: public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        qDebug("Called before everything else.");
    }

    void myFirstTest()
    {
        QVERIFY(true);
    }
};

QTEST_MAIN(tst_ClientLRC)

#include "tst_clientLRC.moc"
#endif
