#ifndef SPELLCORRECTORHANDLER_H
#define SPELLCORRECTORHANDLER_H

#include <QObject>

class SpellCorrectorHandler : public QObject
{
    Q_OBJECT
public:
    explicit SpellCorrectorHandler(QObject* parent = nullptr);


};

#endif // SPELLCORRECTORHANDLER_H
