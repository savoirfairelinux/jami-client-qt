// MyModel.h
#pragma once

#include <QAbstractListModel>
#include <QList>

class MyModel : public QAbstractListModel
{
    Q_OBJECT

public:
    MyModel(QObject* parent = nullptr);

    // Les fonctions virtuelles à implémenter
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

private:
    QList<QString> m_data;
};