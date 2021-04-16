#include "conversationlistmodel.h"

ConversationListModel::ConversationListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    model_ = lrcInstance_->getCurrentConversationModel();

    connect(
        model_,
        &ConversationModel::beginInsertRows,
        this,
        [this](int position, int rows) {
            beginInsertRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);
    connect(model_,
            &ConversationModel::endInsertRows,
            this,
            &ConversationListModel::endInsertRows,
            Qt::DirectConnection);

    connect(
        model_,
        &ConversationModel::beginRemoveRows,
        this,
        [this](int position, int rows) {
            beginRemoveRows(QModelIndex(), position, position + (rows - 1));
        },
        Qt::DirectConnection);
    connect(model_,
            &ConversationModel::endRemoveRows,
            this,
            &ConversationListModel::endRemoveRows,
            Qt::DirectConnection);

    connect(model_, &ConversationModel::dataChanged, this, [this](int position) {
        const auto index = createIndex(position, 0);
        Q_EMIT ConversationListModel::dataChanged(index, index);
    });
}

QVariant
ConversationListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    // FIXME: Implement me!
    return {};
}

int
ConversationListModel::rowCount(const QModelIndex& parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (!parent.isValid() && model_) {
        return model_->getConversations().size();
    }
    return 0;
}

int
ConversationListModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return 1;
}

QVariant
ConversationListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return QVariant();

    const auto& data = model_->getConversations();

    // FIXME: Implement me!
    return QVariant();
}

QHash<int, QByteArray>
ConversationListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DisplayName] = "DisplayName";
    roles[DisplayID] = "DisplayID";
    roles[Presence] = "Presence";
    roles[URI] = "URI";
    roles[UnreadMessagesCount] = "UnreadMessagesCount";
    roles[LastInteractionDate] = "LastInteractionDate";
    roles[LastInteraction] = "LastInteraction";
    roles[ContactType] = "ContactType";
    roles[UID] = "UID";
    roles[InCall] = "InCall";
    roles[IsAudioOnly] = "IsAudioOnly";
    roles[CallStackViewShouldShow] = "CallStackViewShouldShow";
    roles[CallState] = "CallState";
    roles[SectionName] = "SectionName";
    roles[AccountId] = "AccountId";
    roles[Draft] = "Draft";
    roles[PictureUid] = "PictureUid";
    return roles;
}

Qt::ItemFlags
ConversationListModel::flags(const QModelIndex& index) const
{
    auto flags = QAbstractItemModel::flags(index) | Qt::ItemNeverHasChildren | Qt::ItemIsSelectable;
    auto type = static_cast<lrc::api::profile::Type>(data(index, Role::ContactType).value<int>());
    auto uid = data(index, Role::UID).value<QString>();
    if (!index.isValid()) {
        return QAbstractItemModel::flags(index);
    } else if ((type == lrc::api::profile::Type::TEMPORARY && uid.isEmpty())) {
        flags &= ~(Qt::ItemIsSelectable);
    }
    return flags;
}

ConversationListProxyModel::ConversationListProxyModel(QAbstractListModel* parent)
    : QSortFilterProxyModel(parent)
    , selectedSourceIndex_(QModelIndex())
{
    setSourceModel(parent);
    setSortRole(ConversationListModel::Role::LastInteractionDate);
    sort(0, Qt::DescendingOrder);
    connect(sourceModel(),
            &QAbstractListModel::dataChanged,
            this,
            &ConversationListProxyModel::updateSelection);
    connect(sourceModel(),
            &QAbstractListModel::rowsInserted,
            this,
            &ConversationListProxyModel::updateSelection);
    connect(sourceModel(),
            &QAbstractListModel::rowsRemoved,
            this,
            &ConversationListProxyModel::updateSelection);
}

bool
ConversationListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    int filterRole = ConversationListModel::Role::DisplayName;
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    return (index.data(filterRole).toString().contains(filterRegExp()));
}

bool
ConversationListProxyModel::lessThan(const QModelIndex& left, const QModelIndex& right) const
{
    QVariant leftData = sourceModel()->data(left, sortRole());
    QVariant rightData = sourceModel()->data(right, sortRole());

    return leftData.toUInt() < rightData.toUInt();
}

void
ConversationListProxyModel::setFilter(const QString& filterString)
{
    setFilterRegExp(filterString);
    updateSelection();
}

void
ConversationListProxyModel::select(const QModelIndex& index)
{
    selectedSourceIndex_ = mapToSource(index);
    updateSelection();
}

void
ConversationListProxyModel::select(int row)
{
    select(index(row, 0));
}

int
ConversationListProxyModel::currentFilteredRow()
{
    return currentFilteredRow_;
}

QVariant
ConversationListProxyModel::dataForRow(int row, int role) const
{
    return data(index(row, 0), role);
}

void
ConversationListProxyModel::setCurrentFilteredRow(int currentFilteredRow)
{
    if (currentFilteredRow_ == currentFilteredRow)
        return;
    currentFilteredRow_ = currentFilteredRow;
    Q_EMIT currentFilteredRowChanged(currentFilteredRow_);
}

void
ConversationListProxyModel::updateSelection()
{
    auto filteredIndex = mapFromSource(selectedSourceIndex_);

    // if the source model is empty, invalidate the selection
    if (sourceModel()->rowCount() == 0) {
        setCurrentFilteredRow(-1);
        Q_EMIT validSelectionChanged();
        return;
    }

    // if the source and filtered index is no longer valid
    // this would indicate that a mutation has occured,
    // thus any arbritrary ux decision is okay here
    if (!selectedSourceIndex_.isValid()) {
        auto row = qMax(--currentFilteredRow_, 0);
        selectedSourceIndex_ = mapToSource(index(row, 0));
        filteredIndex = mapFromSource(selectedSourceIndex_);
        currentFilteredRow_ = filteredIndex.row();
        Q_EMIT currentFilteredRowChanged(currentFilteredRow_);
        Q_EMIT validSelectionChanged();
        return;
    }

    // update the row for ListView observers
    setCurrentFilteredRow(filteredIndex.row());

    // finally, if the filter index is invalid, then we have
    // probably just filtered out the selected item and don't
    // want to force reselection of other ui components, as the
    // source index is still valid
    if (filteredIndex.isValid())
        Q_EMIT validSelectionChanged();
}
