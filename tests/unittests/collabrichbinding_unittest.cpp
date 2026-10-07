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

#include "globaltestenvironment.h"

#include "collabrichbinding.h"

#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickTextDocument>
#include <QTextBlock>
#include <QTextDocument>
#include <QTextList>
#include <QJsonDocument>
#include <QJsonArray>

class CollabRichBindingFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        // The binding only takes a document from a TextEdit, so one is built the
        // way the editor builds it.
        component.reset(new QQmlComponent(&engine));
        component->setData("import QtQuick\nTextEdit { textFormat: TextEdit.RichText }", QUrl());
        edit.reset(component->create());
        ASSERT_TRUE(edit) << component->errorString().toStdString();
        auto* quickDoc = edit->property("textDocument").value<QQuickTextDocument*>();
        ASSERT_TRUE(quickDoc);
        binding.reset(new CollabRichBinding());
        binding->setTextDocument(quickDoc);
        doc = quickDoc->textDocument();
    }

    // How far left of the text the line is pushed, counting both what the block
    // asks for and what its list adds. This is what the two replicas have to
    // agree on.
    int indentOf(int blockNumber) const
    {
        const QTextBlock blk = doc->findBlockByNumber(blockNumber);
        const int listIndent = blk.textList() ? blk.textList()->format().indent() : 0;
        return blk.blockFormat().indent() + listIndent;
    }

    QQmlEngine engine;
    QScopedPointer<QQmlComponent> component;
    QScopedPointer<QObject> edit;
    QScopedPointer<CollabRichBinding> binding;
    QTextDocument* doc {nullptr};
};

/*!
 * GIVEN A bulleted line that is momentarily empty, as it is between pressing
 *       Enter and typing the next item
 * WHEN  The character that makes it a list item again arrives
 * THEN  It is drawn at the same indent as the items around it
 *
 * QTextList::remove() stamps the list's own indent onto the block it drops, so
 * without care the line comes back one level deeper -- and only on the replica
 * that saw it empty, which is the replica that did not type it.
 */
TEST_F(CollabRichBindingFixture, EmptyListLineRejoiningKeepsItsIndent)
{
    binding->loadContentDelta(R"([{"insert":"1","attributes":{"list":"bullet"}},{"insert":"\n"},)"
                              R"({"insert":"2","attributes":{"list":"bullet"}}])");
    ASSERT_EQ(doc->blockCount(), 2);
    const int settled = indentOf(0);

    // Enter at the end: the new line exists before anything is typed on it.
    binding->applyRemoteDelta(R"([{"retain":3},{"insert":"\n"}])");
    ASSERT_EQ(doc->blockCount(), 3);

    // ...and now the item is typed on it.
    binding->applyRemoteDelta(R"([{"retain":4},{"insert":"3","attributes":{"list":"bullet"}}])");
    ASSERT_EQ(doc->blockCount(), 3);

    EXPECT_EQ(indentOf(2), settled);
    EXPECT_EQ(indentOf(2), indentOf(1));
}

/*!
 * GIVEN A bulleted line
 * WHEN  Its list attribute is taken away
 * THEN  It is drawn where an ordinary paragraph is, not where the list was
 */
TEST_F(CollabRichBindingFixture, LineLeavingAListIsNotLeftIndented)
{
    binding->loadContentDelta(R"([{"insert":"1","attributes":{"list":"bullet"}}])");
    binding->applyRemoteDelta(R"([{"retain":1,"attributes":{"list":null}}])");

    EXPECT_EQ(indentOf(0), 0);
}

/*!
 * GIVEN A peer's caret, announced at an index of the document as it then was
 * WHEN  An edit arrives before the next announcement does
 * THEN  The caret is carried along by it, rather than left pointing at what the
 *       text used to be
 */
TEST_F(CollabRichBindingFixture, ARemoteCaretIsCarriedAlongByAnArrivingEdit)
{
    const QVariantList carets {0, 5, 11};

    // Three characters typed at 5: everything from there on moves along.
    EXPECT_EQ(binding->transformPositions(R"([{"retain":5},{"insert":"XYZ"}])", carets), (QVariantList {0, 8, 14}));

    // Three characters taken away at 5: the caret inside them collapses onto the
    // hole, the one after it moves back by the whole three.
    EXPECT_EQ(binding->transformPositions(R"([{"retain":4},{"delete":3}])", carets), (QVariantList {0, 4, 8}));

    // A picture is one unit however many bytes it is.
    EXPECT_EQ(binding->transformPositions(R"([{"retain":5},{"insert":{"image":{"id":"a"}}}])", carets),
              (QVariantList {0, 6, 12}));

    // Formatting moves nothing.
    EXPECT_EQ(binding->transformPositions(R"([{"retain":11,"attributes":{"b":true}}])", carets), carets);

    // A delta that is not one leaves every caret where it was.
    EXPECT_EQ(binding->transformPositions(QStringLiteral("not json"), carets), carets);
}

/*!
 * GIVEN A document whose lists are already what its characters say they are
 * WHEN  A remote edit arrives that changes none of them
 * THEN  The editor is told about the document once, not once per operation and
 *       once per line
 *
 * Every change the editor is told about is a layout and a caret moved, which is
 * what the peers who did not type see as a flicker.
 */
TEST_F(CollabRichBindingFixture, AnArrivingEditIsOneChangeToTheDocument)
{
    binding->loadContentDelta(R"([{"insert":"one","attributes":{"list":"bullet"}},{"insert":"\n"},)"
                              R"({"insert":"two","attributes":{"list":"bullet"}},{"insert":"\n"},)"
                              R"({"insert":"three","attributes":{"list":"bullet"}}])");

    int changes = 0;
    QObject::connect(doc, &QTextDocument::contentsChange, [&changes](int, int, int) { ++changes; });
    binding->applyRemoteDelta(R"([{"retain":4},{"insert":"a","attributes":{"list":"bullet"}}])");

    EXPECT_EQ(changes, 1);
    EXPECT_EQ(doc->toPlainText(), QStringLiteral("one\natwo\nthree"));
}

/*!
 * GIVEN Two bulleted runs with an ordinary line between them
 * WHEN  The lists are reconciled
 * THEN  They are two lists, so an ordered one starts counting again after the
 *       gap rather than carrying on through it
 */
TEST_F(CollabRichBindingFixture, ARunAfterAGapIsAListOfItsOwn)
{
    binding->loadContentDelta(R"([{"insert":"one","attributes":{"list":"ordered"}},{"insert":"\n"},)"
                              R"({"insert":"break"},{"insert":"\n"},)"
                              R"({"insert":"two","attributes":{"list":"ordered"}}])");

    ASSERT_EQ(doc->blockCount(), 3);
    QTextList* first = doc->findBlockByNumber(0).textList();
    QTextList* second = doc->findBlockByNumber(2).textList();
    ASSERT_TRUE(first);
    ASSERT_TRUE(second);
    EXPECT_NE(first, second);
    EXPECT_FALSE(doc->findBlockByNumber(1).textList());

    // ...and it stays that way when a later edit reconciles them again.
    binding->applyRemoteDelta(R"([{"retain":13},{"insert":"!","attributes":{"list":"ordered"}}])");
    EXPECT_NE(doc->findBlockByNumber(0).textList(), doc->findBlockByNumber(2).textList());
}

/*!
 * GIVEN A local edit
 * WHEN  It is reported
 * THEN  The revision is bumped after the delta has gone out, never before
 *
 * A binding woken by the revision may go on to ask the daemon what the
 * document now holds, and the edit has not reached it until the delta has.
 */
TEST_F(CollabRichBindingFixture, TheRevisionIsBumpedAfterTheDeltaHasGoneOut)
{
    QStringList order;
    QObject::connect(binding.data(), &CollabRichBinding::localDelta, [&order](const QString&) {
        order << QStringLiteral("delta");
    });
    QObject::connect(binding.data(), &CollabRichBinding::revisionChanged, [&order]() {
        order << QStringLiteral("revision");
    });

    QTextCursor c(doc);
    c.insertText(QStringLiteral("typed"));

    EXPECT_EQ(order, (QStringList {QStringLiteral("delta"), QStringLiteral("revision")}));
    EXPECT_EQ(binding->revision(), 1);
}

TEST_F(CollabRichBindingFixture, FontIdsAreRenderedAndReported)
{
    for (const auto& id : {"sans-serif", "serif", "monospace", "cursive"}) {
        const QString fontId = QString::fromLatin1(id);
        binding->loadContentDelta(
            QStringLiteral("[{\"insert\":\"Report\",\"attributes\":{\"font\":\"%1\"}}]").arg(fontId));

        EXPECT_EQ(binding->selectionFormat(0, 6).value(QStringLiteral("font")).toString(), fontId);
        QTextCursor cursor(doc);
        cursor.setPosition(1);
        EXPECT_FALSE(cursor.charFormat().fontFamilies().toStringList().isEmpty());
    }
}

TEST_F(CollabRichBindingFixture, SelectingAFontWritesItsPortableId)
{
    binding->loadContentDelta(R"([{"insert":"A report"}])");
    QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);

    ASSERT_TRUE(QMetaObject::invokeMethod(binding.data(),
                                          "setFont",
                                          Q_ARG(QString, QStringLiteral("serif")),
                                          Q_ARG(int, 2),
                                          Q_ARG(int, 8)));

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.at(0).at(0).toString().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":2},{"retain":6,"attributes":{"font":"serif"}}])"));
    EXPECT_EQ(binding->selectionFormat(2, 8).value(QStringLiteral("font")).toString(), QStringLiteral("serif"));
    EXPECT_TRUE(binding->selectionFormat(0, 1).value(QStringLiteral("font")).toString().isEmpty());
}

TEST_F(CollabRichBindingFixture, ChoosingAFontInsideAWordFormatsTheWord)
{
    binding->loadContentDelta(R"([{"insert":"A report today"}])");
    QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);

    binding->setFont(QStringLiteral("cursive"), 4, 4);

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.at(0).at(0).toString().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":2},{"retain":6,"attributes":{"font":"cursive"}}])"));
}

TEST_F(CollabRichBindingFixture, ChoosingAFontAtTheCaretFormatsTheNextText)
{
    QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);
    binding->setFont(QStringLiteral("monospace"), 0, 0);

    EXPECT_TRUE(deltas.isEmpty());
    EXPECT_EQ(binding->selectionFormat(0, 0).value(QStringLiteral("font")).toString(), QStringLiteral("monospace"));
    ASSERT_TRUE(QMetaObject::invokeMethod(edit.data(), "insert", Q_ARG(int, 0), Q_ARG(QString, QStringLiteral("Hi"))));

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.at(0).at(0).toString().toUtf8()),
              QJsonDocument::fromJson(R"([{"insert":"Hi","attributes":{"font":"monospace"}}])"));
    EXPECT_EQ(binding->selectionFormat(0, 2).value(QStringLiteral("font")).toString(), QStringLiteral("monospace"));
}

TEST_F(CollabRichBindingFixture, DefaultAndClearFormattingRemoveTheFont)
{
    for (const bool clearAll : {false, true}) {
        binding->loadContentDelta(R"([{"insert":"Report","attributes":{"font":"serif","b":true}}])");
        QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);
        if (clearAll)
            binding->clearFormat(0, 6);
        else
            binding->setFont(QString(), 0, 6);

        ASSERT_EQ(deltas.size(), 1);
        const QJsonObject attributes = QJsonDocument::fromJson(deltas.at(0).at(0).toString().toUtf8())
                                           .array()
                                           .at(0)
                                           .toObject()
                                           .value(QStringLiteral("attributes"))
                                           .toObject();
        EXPECT_TRUE(attributes.value(QStringLiteral("font")).isNull());
        EXPECT_TRUE(binding->selectionFormat(0, 6).value(QStringLiteral("font")).toString().isEmpty());
        EXPECT_EQ(binding->selectionFormat(0, 6).value(QStringLiteral("b")).toBool(), !clearAll);
        QTextCursor cursor(doc);
        cursor.setPosition(1);
        EXPECT_TRUE(cursor.charFormat().fontFamilies().toStringList().isEmpty());
    }
}

TEST_F(CollabRichBindingFixture, TypedTextKeepsAnUnknownPortableFontId)
{
    binding->loadContentDelta(R"([{"insert":"A","attributes":{"font":"future-font"}}])");
    QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);
    QTextCursor cursor(doc);
    cursor.setPosition(1);
    EXPECT_EQ(cursor.charFormat().fontFamilies().toStringList(), (QStringList {QStringLiteral("future-font")}));
    cursor.insertText(QStringLiteral("B"));

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.at(0).at(0).toString().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":1},{"insert":"B","attributes":{"font":"future-font"}}])"));
}

TEST_F(CollabRichBindingFixture, InvalidFontIdsAreNotWrittenOrRendered)
{
    for (const auto& id : {"Serif", "serif; color:red", "../serif"}) {
        const QString fontId = QString::fromLatin1(id);
        binding->loadContentDelta(QStringLiteral("[{\"insert\":\"A\",\"attributes\":{\"font\":\"%1\"}}]").arg(fontId));
        EXPECT_TRUE(binding->selectionFormat(0, 1).value(QStringLiteral("font")).toString().isEmpty());
        QSignalSpy deltas(binding.data(), &CollabRichBinding::localDelta);
        binding->setFont(fontId, 0, 1);
        EXPECT_TRUE(deltas.isEmpty());
    }
}

TEST_F(CollabRichBindingFixture, ARemoteEditCarriesThePendingFontWithTheCaret)
{
    binding->loadContentDelta(R"([{"insert":"A "}])");
    binding->setFont(QStringLiteral("monospace"), 2, 2);
    binding->applyRemoteDelta(R"([{"insert":"Hello "}])");

    EXPECT_EQ(binding->selectionFormat(8, 8).value(QStringLiteral("font")).toString(), QStringLiteral("monospace"));
}
