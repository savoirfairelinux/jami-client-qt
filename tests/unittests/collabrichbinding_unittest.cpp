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
