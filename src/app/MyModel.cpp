#include "MyModel.h"

MyModel::MyModel(QObject* parent)
    : QAbstractListModel(parent)
{
    // Initialisez votre modèle de données ici
    m_data << "Donnée 1"
           << "Donnée 2"
           << "Donnée 3";
}

int
MyModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_data.count();
}

QVariant
MyModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    if (role == Qt::DisplayRole) {
        return m_data.at(index.row());
    }

    return QVariant();
}