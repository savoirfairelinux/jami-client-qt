#pragma once

#include "abstractlistmodelbase.h"

#include <QSortFilterProxyModel>

// A wrapper view model around ConversationModel's underlying data
class ConversationListModel : public AbstractListModelBase
{
    Q_OBJECT

public:
    using AccountInfo = lrc::api::account::Info;
    using ConversationInfo = lrc::api::conversation::Info;
    using ContactInfo = lrc::api::contact::Info;

    enum Role {
        DisplayName = Qt::UserRole + 1,
        DisplayID,
        Presence,
        URI,
        UnreadMessagesCount,
        LastInteractionDate,
        LastInteraction,
        LastInteractionType,
        ContactType,
        UID,
        ContextMenuOpen,
        InCall,
        IsAudioOnly,
        CallStackViewShouldShow,
        CallState,
        SectionName,
        AccountId,
        PictureUid,
        Draft
    };
    Q_ENUM(Role)

    explicit ConversationListModel(LRCInstance* instance, QObject* parent = nullptr);

    // Header:
    QVariant headerData(int section,
                        Qt::Orientation orientation,
                        int role = Qt::DisplayRole) const override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

private:
    // convenience pointer to be pulled from lrcinstance
    ConversationModel* model_;
};

// The top level filtered and sorted model to be consumed by QML ListViews
class ConversationListProxyModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int currentFilteredRow READ currentFilteredRow WRITE setCurrentFilteredRow NOTIFY
                   currentFilteredRowChanged)

public:
    explicit ConversationListProxyModel(QAbstractListModel* parent);

    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

    Q_INVOKABLE void setFilter(const QString& filterString);
    Q_INVOKABLE void select(const QModelIndex& index);
    Q_INVOKABLE void select(int row);
    Q_INVOKABLE int currentFilteredRow();
    Q_INVOKABLE QVariant dataForRow(int row, int role = Qt::DisplayRole) const;

public Q_SLOTS:
    void setCurrentFilteredRow(int currentFilteredRow);

private Q_SLOTS:
    void updateSelection();

Q_SIGNALS:
    void currentFilteredRowChanged(int currentFilteredRow);
    void validSelectionChanged();

private:
    // this is a cut down replacement for QItemSelectionModel
    QPersistentModelIndex selectedSourceIndex_;
    int currentFilteredRow_ {-1};
};
