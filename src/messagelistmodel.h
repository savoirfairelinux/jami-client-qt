#ifndef MESSAGELISTMODEL_H
#define MESSAGELISTMODEL_H
#include "abstractlistmodelbase.h"

class MessageListModel : public AbstractListModelBase
{
    Q_OBJECT

public:
    enum Role { Content };
    Q_ENUMS(Role)
    explicit MessageListModel(LRCInstance* instance, QObject* parent = nullptr);
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    Q_INVOKABLE void insertMessage(const QString& line);
    Q_INVOKABLE void removeLine();
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void clearModel();

protected:
    // Convenience pointer to be pulled from lrcinstance
    ConversationModel* model_;
    // LRCInstance pointer (set in qml)
    LRCInstance* lrcInstance_ {nullptr};
};

#endif // MESSAGELISTMODEL_H
