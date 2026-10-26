/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "messagesadapter.h"
#include "threadedmsglistmodel.h"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QSignalSpy>

#include <gtest/gtest.h>

using namespace lrc::api;

namespace {

interaction::Info
message(const QString& replyTo = {}, interaction::Type type = interaction::Type::TEXT)
{
    interaction::Info info;
    info.type = type;
    info.body = QStringLiteral("body");
    if (!replyTo.isEmpty())
        info.commit[QStringLiteral("reply-to")] = replyTo;
    return info;
}

struct ThreadedFixture
{
    MessageListModel source {nullptr};
    FilteredMsgListModel filtered;
    ThreadedMsgListModel threaded;

    ThreadedFixture()
    {
        filtered.setSourceModel(&source);
        threaded.setSourceModel(&filtered);
    }

    // Live arrival: newest message, appended at the end of the history.
    void add(const QString& id, const QString& replyTo = {}, interaction::Type type = interaction::Type::TEXT)
    {
        ASSERT_TRUE(source.append(id, message(replyTo, type)));
    }

    // History paging: an older message, inserted before everything loaded so far.
    void addOlder(const QString& id, const QString& replyTo = {})
    {
        ASSERT_TRUE(source.insert(id, message(replyTo), 0));
    }

    // Visible ids, oldest first, once pending regrouping has been applied.
    QStringList ids() const
    {
        QCoreApplication::processEvents();
        QStringList result;
        for (int row = threaded.rowCount() - 1; row >= 0; --row)
            result << threaded.index(row, 0).data(MessageList::Id).toString();
        return result;
    }

    int replyCount(const QString& id) const
    {
        const auto row = const_cast<ThreadedMsgListModel&>(threaded).getDisplayIndex(id);
        return threaded.index(row, 0).data(ThreadedMsgListModel::ThreadReplyCount).toInt();
    }
};

} // namespace

TEST(ThreadedMsgListModel, RootListShowsOnlyRootsInOriginalOrder)
{
    ThreadedFixture f;
    f.add("a");
    f.add("b");
    f.add("a1", "a");
    f.add("c");
    f.add("a2", "a1");

    EXPECT_EQ(f.ids(), QStringList({"a", "b", "c"}));
}

TEST(ThreadedMsgListModel, SelectedThreadShowsRootAndNestedReplies)
{
    ThreadedFixture f;
    f.add("a");
    f.add("b");
    f.add("a1", "a");
    f.add("b1", "b");
    f.add("a2", "a1");

    QSignalSpy countSpy(&f.threaded, &ThreadedMsgListModel::countChanged);
    f.threaded.setThreadId("a");

    EXPECT_EQ(f.ids(), QStringList({"a", "a1", "a2"}));
    EXPECT_FALSE(countSpy.isEmpty());

    f.threaded.setThreadId({});
    EXPECT_EQ(f.ids(), QStringList({"a", "b"}));
}

TEST(ThreadedMsgListModel, ReplyCountsIncludeLoadedNestedReplies)
{
    ThreadedFixture f;
    f.add("a");
    f.add("b");
    f.add("a1", "a");
    f.add("a2", "a1");

    EXPECT_EQ(f.replyCount("a"), 2);
    EXPECT_EQ(f.replyCount("b"), 0);
    EXPECT_EQ(f.threaded.threadRootOf("a2"), QStringLiteral("a"));

    QSignalSpy changedSpy(&f.threaded, &QAbstractItemModel::dataChanged);
    f.add("a3", "a");
    EXPECT_EQ(f.replyCount("a"), 3);
    bool countChanged = false;
    for (const auto& args : changedSpy)
        countChanged |= args.at(2).value<QList<int>>().contains(ThreadedMsgListModel::ThreadReplyCount);
    EXPECT_TRUE(countChanged);
}

TEST(ThreadedMsgListModel, ReplyWithMissingParentStaysVisibleAsRoot)
{
    ThreadedFixture f;
    f.add("x1", "not-loaded");
    f.add("x2", "x1");

    EXPECT_EQ(f.ids(), QStringList({"x1"}));
    EXPECT_EQ(f.replyCount("x1"), 1);
    f.threaded.setThreadId("x1");
    EXPECT_EQ(f.ids(), QStringList({"x1", "x2"}));
}

TEST(ThreadedMsgListModel, ReplyToUndisplayableParentStaysVisibleAsRoot)
{
    ThreadedFixture f;
    f.add("hidden", {}, interaction::Type::MERGE);
    f.add("r", "hidden");

    EXPECT_EQ(f.ids(), QStringList({"r"}));
}

TEST(ThreadedMsgListModel, LateParentRegroupsFallbackRootsAndKeepsSelection)
{
    ThreadedFixture f;
    f.add("other");
    f.add("x1", "p");
    f.add("x2", "x1");
    f.threaded.setThreadId("x1");

    QSignalSpy threadSpy(&f.threaded, &ThreadedMsgListModel::threadIdChanged);
    f.addOlder("p");

    EXPECT_EQ(f.threaded.threadId(), QStringLiteral("p"));
    EXPECT_EQ(threadSpy.count(), 1);
    EXPECT_EQ(f.ids(), QStringList({"p", "x1", "x2"}));

    f.threaded.setThreadId({});
    EXPECT_EQ(f.ids(), QStringList({"p", "other"}));
    EXPECT_EQ(f.replyCount("p"), 2);
}

TEST(ThreadedMsgListModel, ClearingSourceForgetsThreads)
{
    ThreadedFixture f;
    f.add("a");
    f.add("a1", "a");
    f.source.clear();

    EXPECT_TRUE(f.ids().isEmpty());
    EXPECT_TRUE(f.threaded.threadRootOf("a1").isEmpty());

    f.add("a1", "a");
    EXPECT_EQ(f.ids(), QStringList({"a1"}));
}

TEST(ThreadedMsgListModel, MovedMessageKeepsThreadMembership)
{
    ThreadedFixture f;
    f.add("a");
    f.add("b");
    f.add("a1", "a");

    auto moved = message("a");
    moved.parentId = "a";
    ASSERT_TRUE(f.source.update("a1", moved));

    EXPECT_EQ(f.ids(), QStringList({"a", "b"}));
    EXPECT_EQ(f.replyCount("a"), 1);
}

TEST(ThreadedMsgListModel, LoadingLongNestedChainFromNewestToOldest)
{
    // Older history is inserted at the top, so each older message is the parent of everything
    // already loaded. This must not re-walk the loaded chain for every page.
    constexpr int chainLength = 5000;
    ThreadedFixture f;
    QElapsedTimer timer;
    timer.start();
    for (int i = chainLength - 1; i >= 0; --i) {
        f.addOlder(QString::number(i), i == 0 ? QString() : QString::number(i - 1));
        if (i % 20 == 0)
            QCoreApplication::processEvents(); // History arrives in 20-message batches.
    }
    const auto elapsed = timer.elapsed();

    EXPECT_EQ(f.ids(), QStringList({"0"}));
    EXPECT_EQ(f.replyCount("0"), chainLength - 1);
    EXPECT_EQ(f.threaded.threadRootOf(QString::number(chainLength - 1)), QStringLiteral("0"));
    std::cout << "Loaded a " << chainLength << "-message nested chain in " << elapsed << " ms" << std::endl;
}

TEST(ThreadedHistoryRequest, OnlyOneRequestIsInFlight)
{
    HistoryRequest request;
    EXPECT_TRUE(request.start("acc", "conv", 7, 10));
    EXPECT_FALSE(request.start("acc", "conv", 8, 10));
    EXPECT_TRUE(request.pending());
}

TEST(ThreadedHistoryRequest, StaleOrForeignCallbacksAreIgnored)
{
    HistoryRequest request;
    request.start("acc", "conv", 7, 10);
    EXPECT_EQ(request.finish("acc", "conv", 8, 30), HistoryRequest::Ignored);
    EXPECT_EQ(request.finish("acc", "other", 7, 30), HistoryRequest::Ignored);
    EXPECT_EQ(request.finish("other", "conv", 7, 30), HistoryRequest::Ignored);
    EXPECT_TRUE(request.pending());
    EXPECT_EQ(request.finish("acc", "conv", 7, 30), HistoryRequest::Progress);
    EXPECT_FALSE(request.pending());
    EXPECT_EQ(request.finish("acc", "conv", 7, 50), HistoryRequest::Ignored);
}

TEST(ThreadedHistoryRequest, EmptyBatchIsReportedAsNoProgress)
{
    HistoryRequest request;
    request.start("acc", "conv", 7, 10);
    EXPECT_EQ(request.finish("acc", "conv", 7, 10), HistoryRequest::NoProgress);
}

TEST(ThreadedHistoryRequest, FailedOrCompleteRequestsAreNotTracked)
{
    HistoryRequest request;
    EXPECT_FALSE(request.start("acc", "conv", 0, 10));  // daemon refused
    EXPECT_FALSE(request.start("acc", "conv", -1, 10)); // all messages already loaded
    EXPECT_FALSE(request.pending());
}

TEST(ThreadedHistoryRequest, ResetDropsTheRequest)
{
    HistoryRequest request;
    request.start("acc", "conv", 7, 10);
    request.reset();
    EXPECT_FALSE(request.pending());
    EXPECT_EQ(request.finish("acc", "conv", 7, 30), HistoryRequest::Ignored);
}
