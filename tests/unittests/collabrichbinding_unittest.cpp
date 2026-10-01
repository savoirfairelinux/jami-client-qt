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

#include <QFontInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickTextDocument>
#include <QTextBlock>
#include <QTextCursor>
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
        QObject::connect(binding.data(), &CollabRichBinding::localDelta, [this](const QString& delta) {
            deltas << delta;
        });
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

    // The format of the character at @p index.
    QTextCharFormat formatAt(int index) const
    {
        QTextCursor c(doc);
        c.setPosition(index + 1);
        return c.charFormat();
    }

    // What the editor does with a keystroke: the text takes the format of the
    // character before it.
    void type(int position, const QString& text)
    {
        QTextCursor c(doc);
        c.setPosition(position);
        c.insertText(text);
    }

    QQmlEngine engine;
    QScopedPointer<QQmlComponent> component;
    QScopedPointer<QObject> edit;
    QScopedPointer<CollabRichBinding> binding;
    QTextDocument* doc {nullptr};
    // Every delta the binding sent, in order.
    QStringList deltas;
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

/*!
 * GIVEN The fonts a document may name
 * WHEN  The editor offers them
 * THEN  Each one has been loaded from the client's own files, under the id the
 *       other clients know it by
 *
 * What the machine happens to have installed under the same name proves
 * nothing: a document has to read the same on a machine that has none of them.
 */
TEST_F(CollabRichBindingFixture, EveryOfferedFontIsLoadedFromTheClient)
{
    const QVariantList fonts = binding->fonts();
    QStringList ids;
    for (const QVariant& entry : fonts) {
        const QVariantMap font = entry.toMap();
        ids << font.value(QStringLiteral("id")).toString();
        EXPECT_EQ(CollabRichBinding::fontFamily(ids.last()), font.value(QStringLiteral("family")).toString());
    }
    EXPECT_EQ(ids,
              (QStringList {"liberation-sans",
                            "liberation-serif",
                            "liberation-mono",
                            "carlito",
                            "caladea",
                            "gelasio",
                            "eb-garamond",
                            "roboto",
                            "open-sans",
                            "comic-neue"}));
    EXPECT_TRUE(CollabRichBinding::fontFamily(QStringLiteral("no-such-font")).isEmpty());
}

/*!
 * GIVEN A document naming a font for part of its text
 * WHEN  It is opened
 * THEN  That part is drawn in the font, the rest in the editor's own
 */
TEST_F(CollabRichBindingFixture, NamedFontIsDrawnInIt)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"liberation-serif"}},{"insert":"def"}])");

    EXPECT_EQ(formatAt(0).fontFamilies().toStringList().value(0), QStringLiteral("Liberation Serif"));
    EXPECT_EQ(QFontInfo(formatAt(2).font()).family(), QStringLiteral("Liberation Serif"));
    EXPECT_FALSE(formatAt(3).hasProperty(QTextFormat::FontFamilies));
}

/*!
 * GIVEN Text in a font
 * WHEN  Something is typed inside it
 * THEN  What is typed is in the font too, and the other participants are told
 */
TEST_F(CollabRichBindingFixture, TextTypedInAFontIsSentInIt)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"roboto"}}])");
    type(3, QStringLiteral("d"));

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":3},{"insert":"d","attributes":{"font":"roboto"}}])"));
}

/*!
 * GIVEN Text in a font
 * WHEN  A peer's text arrives next to it, naming no font
 * THEN  It is drawn in the editor's own font, as it is on the peer's screen
 */
TEST_F(CollabRichBindingFixture, ArrivingTextDoesNotTakeTheFontNextToIt)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"roboto"}}])");
    binding->applyRemoteDelta(R"([{"retain":3},{"insert":"d"}])");

    EXPECT_FALSE(formatAt(3).hasProperty(QTextFormat::FontFamilies));
}

/*!
 * GIVEN A selection
 * WHEN  A font is chosen for it
 * THEN  It alone takes the font, the toolbar says so, and the change is sent
 */
TEST_F(CollabRichBindingFixture, ChosenFontAppliesToTheSelection)
{
    binding->loadContentDelta(R"([{"insert":"hello world"}])");
    binding->setFont(QStringLiteral("carlito"), 0, 5);

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":5,"attributes":{"font":"carlito"}}])"));
    EXPECT_EQ(formatAt(4).fontFamilies().toStringList().value(0), QStringLiteral("Carlito"));
    EXPECT_FALSE(formatAt(5).hasProperty(QTextFormat::FontFamilies));
    EXPECT_EQ(binding->selectionFormat(0, 5).value(QStringLiteral("font")).toString(), QStringLiteral("carlito"));
    EXPECT_EQ(binding->selectionFormat(6, 11).value(QStringLiteral("font")).toString(), QString());
}

/*!
 * GIVEN Two paragraphs in a font
 * WHEN  A peer takes the font away
 * THEN  Both go back to the editor's own font, and so does the separator
 *       between them: a paragraph emptied and typed into again would otherwise
 *       come back in the old font, on this replica only
 */
TEST_F(CollabRichBindingFixture, RemovedFontGivesTheEditorFontBack)
{
    binding->loadContentDelta(R"([{"insert":"ab\ncd","attributes":{"font":"gelasio"}}])");
    ASSERT_TRUE(doc->findBlockByNumber(1).charFormat().hasProperty(QTextFormat::FontFamilies));

    binding->applyRemoteDelta(R"([{"retain":5,"attributes":{"font":null}}])");

    for (int i = 0; i < 5; ++i)
        EXPECT_FALSE(formatAt(i).hasProperty(QTextFormat::FontFamilies)) << "at " << i;
    EXPECT_FALSE(doc->findBlockByNumber(1).charFormat().hasProperty(QTextFormat::FontFamilies));
    type(5, QStringLiteral("e"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":5},{"insert":"e"}])"));
}

/*!
 * GIVEN Text a newer client set in a font this one does not ship
 * WHEN  It is opened, then typed into
 * THEN  It is drawn in the editor's own font, but what is typed still names the
 *       font, so the participants who have it keep seeing one run of text
 */
TEST_F(CollabRichBindingFixture, UnknownFontIsCarriedButNotDrawn)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"roboto"}}])");
    binding->applyRemoteDelta(R"([{"retain":3,"attributes":{"font":"some-future-font"}}])");

    EXPECT_FALSE(formatAt(1).hasProperty(QTextFormat::FontFamilies));
    type(3, QStringLiteral("d"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":3},{"insert":"d","attributes":{"font":"some-future-font"}}])"));
}

/*!
 * GIVEN A font attribute that is no id -- a family name, say, which is what a
 *       peer might write instead
 * WHEN  Text carrying it is typed into
 * THEN  It goes no further
 */
TEST_F(CollabRichBindingFixture, FontThatIsNoIdGoesNoFurther)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"Liberation Sans"}}])");
    type(3, QStringLiteral("d"));

    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":3},{"insert":"d"}])"));
}

/*!
 * GIVEN Text in a font and at a size
 * WHEN  Its formatting is cleared
 * THEN  The font and the size go with the rest
 */
TEST_F(CollabRichBindingFixture, ClearingFormattingRemovesTheFontAndTheSize)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"font":"caladea","size":20,"b":true}}])");
    binding->clearFormat(0, 3);

    const QJsonObject attrs = QJsonDocument::fromJson(deltas.last().toUtf8())
                                  .array()
                                  .last()
                                  .toObject()
                                  .value(QStringLiteral("attributes"))
                                  .toObject();
    EXPECT_EQ(attrs.value(QStringLiteral("font")), QJsonValue(QJsonValue::Null));
    EXPECT_EQ(attrs.value(QStringLiteral("size")), QJsonValue(QJsonValue::Null));
    EXPECT_FALSE(formatAt(1).hasProperty(QTextFormat::FontFamilies));
    EXPECT_FALSE(formatAt(1).hasProperty(QTextFormat::FontPointSize));
    EXPECT_EQ(binding->selectionFormat(0, 3).value(QStringLiteral("font")).toString(), QString());
    EXPECT_EQ(binding->selectionFormat(0, 3).value(QStringLiteral("size")).toDouble(), 0);
}

/*!
 * GIVEN The caret inside a word, nothing selected
 * WHEN  A font is chosen
 * THEN  The whole word takes it, as in a word processor
 */
TEST_F(CollabRichBindingFixture, ChosenFontWithNothingSelectedAppliesToTheWord)
{
    binding->loadContentDelta(R"([{"insert":"hello world"}])");
    binding->setFont(QStringLiteral("eb-garamond"), 8, 8);

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":6},{"retain":5,"attributes":{"font":"eb-garamond"}}])"));
}

/*!
 * GIVEN The caret where no word is, nothing selected
 * WHEN  A font is chosen, then something typed there
 * THEN  Nothing changes until then, and what is typed is in the font
 */
TEST_F(CollabRichBindingFixture, ChosenFontWithNothingSelectedAppliesToWhatIsTypedNext)
{
    binding->loadContentDelta(R"([{"insert":"hello "}])");
    binding->setFont(QStringLiteral("comic-neue"), 6, 6);
    EXPECT_TRUE(deltas.isEmpty());
    EXPECT_EQ(binding->selectionFormat(6, 6).value(QStringLiteral("font")).toString(), QStringLiteral("comic-neue"));

    type(6, QStringLiteral("x"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":6},{"insert":"x","attributes":{"font":"comic-neue"}}])"));
    EXPECT_EQ(formatAt(6).fontFamilies().toStringList().value(0), QStringLiteral("Comic Neue"));

    // ...and what is typed after it carries on in it, as with any format.
    type(7, QStringLiteral("y"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":7},{"insert":"y","attributes":{"font":"comic-neue"}}])"));
}

/*!
 * GIVEN A font chosen for what is typed next
 * WHEN  The caret goes elsewhere before anything is typed
 * THEN  The choice is forgotten, even once the caret comes back
 */
TEST_F(CollabRichBindingFixture, ChosenFontIsForgottenOnceTheCaretMoves)
{
    binding->loadContentDelta(R"([{"insert":"hello "}])");
    binding->setFont(QStringLiteral("comic-neue"), 6, 6);
    binding->caretMoved(2);
    binding->caretMoved(6);

    type(6, QStringLiteral("x"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":6},{"insert":"x"}])"));
}

/*!
 * GIVEN Text in a font, the caret at its end
 * WHEN  The editor's own font is chosen, then something typed
 * THEN  What is typed is in the editor's font and names none
 */
TEST_F(CollabRichBindingFixture, ChoosingTheEditorFontEndsARun)
{
    binding->loadContentDelta(R"([{"insert":"ab","attributes":{"font":"liberation-mono"}}])");
    binding->setFont(QString(), 2, 2);
    type(2, QStringLiteral("c"));

    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":2},{"insert":"c"}])"));
    EXPECT_FALSE(formatAt(2).hasProperty(QTextFormat::FontFamilies));
}

/*!
 * GIVEN A document giving part of its text a size
 * WHEN  It is opened
 * THEN  That part is drawn at the size, the rest at the editor's base size
 */
TEST_F(CollabRichBindingFixture, GivenSizeIsDrawnAtIt)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"size":24}},{"insert":"def"}])");

    EXPECT_EQ(formatAt(1).fontPointSize(), 24);
    EXPECT_FALSE(formatAt(3).hasProperty(QTextFormat::FontPointSize));
}

/*!
 * GIVEN Text at a size
 * WHEN  Something is typed inside it
 * THEN  What is typed is at the size too, and the other participants are told
 */
TEST_F(CollabRichBindingFixture, TextTypedAtASizeIsSentAtIt)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"size":18}}])");
    type(3, QStringLiteral("d"));

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":3},{"insert":"d","attributes":{"size":18}}])"));
}

/*!
 * GIVEN A selection
 * WHEN  A size is chosen for it, then taken away
 * THEN  It takes the size and the toolbar says so, then goes back to the base
 *       size; both changes are sent
 */
TEST_F(CollabRichBindingFixture, ChosenSizeAppliesToTheSelection)
{
    binding->loadContentDelta(R"([{"insert":"hello world"}])");
    binding->setFontSize(14, 0, 5);

    ASSERT_EQ(deltas.size(), 1);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":5,"attributes":{"size":14}}])"));
    EXPECT_EQ(formatAt(4).fontPointSize(), 14);
    EXPECT_FALSE(formatAt(5).hasProperty(QTextFormat::FontPointSize));
    EXPECT_EQ(binding->selectionFormat(0, 5).value(QStringLiteral("size")).toDouble(), 14);
    EXPECT_EQ(binding->selectionFormat(6, 11).value(QStringLiteral("size")).toDouble(), 0);

    binding->setFontSize(0, 0, 5);
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":5,"attributes":{"size":null}}])"));
    EXPECT_FALSE(formatAt(4).hasProperty(QTextFormat::FontPointSize));
}

/*!
 * GIVEN A size no document may have, written by a peer
 * WHEN  Text carrying it arrives, then is typed into
 * THEN  It is neither drawn nor passed on
 */
TEST_F(CollabRichBindingFixture, SizeOutOfBoundsGoesNoFurther)
{
    binding->loadContentDelta(R"([{"insert":"abc","attributes":{"size":100000}}])");
    EXPECT_FALSE(formatAt(1).hasProperty(QTextFormat::FontPointSize));

    type(3, QStringLiteral("d"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":3},{"insert":"d"}])"));
}

/*!
 * GIVEN A heading
 * WHEN  Something is typed at its end
 * THEN  It is part of the heading, for the other participants too
 */
TEST_F(CollabRichBindingFixture, TextTypedInAHeadingIsSentAsPartOfIt)
{
    binding->loadContentDelta(R"([{"insert":"Title","attributes":{"header":2}}])");
    type(5, QStringLiteral("s"));

    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":5},{"insert":"s","attributes":{"header":2}}])"));
    EXPECT_EQ(formatAt(5).intProperty(QTextFormat::FontSizeAdjustment), 2);
}

/*!
 * GIVEN A heading
 * WHEN  A size is chosen for it, then taken away
 * THEN  The chosen size wins over the heading's, as in a word processor, and
 *       the heading's comes back once it is gone; the line stays a heading
 *
 * Qt lets the size adjustment a heading is drawn with override any point size:
 * left to itself, a size chosen inside a heading would show nothing at all.
 */
TEST_F(CollabRichBindingFixture, ChosenSizeWinsOverAHeading)
{
    binding->loadContentDelta(R"([{"insert":"Title","attributes":{"header":1}}])");
    ASSERT_EQ(formatAt(0).intProperty(QTextFormat::FontSizeAdjustment), 3);

    binding->setFontSize(12, 0, 5);
    EXPECT_EQ(formatAt(0).fontPointSize(), 12);
    EXPECT_FALSE(formatAt(0).hasProperty(QTextFormat::FontSizeAdjustment));
    EXPECT_EQ(binding->selectionFormat(0, 5).value(QStringLiteral("header")).toInt(), 1);

    binding->setFontSize(0, 0, 5);
    EXPECT_FALSE(formatAt(0).hasProperty(QTextFormat::FontPointSize));
    EXPECT_EQ(formatAt(0).intProperty(QTextFormat::FontSizeAdjustment), 3);
    EXPECT_EQ(binding->selectionFormat(0, 5).value(QStringLiteral("header")).toInt(), 1);
}

/*!
 * GIVEN Text at a chosen size
 * WHEN  A peer makes its line a heading
 * THEN  The text keeps its size, and the line is a heading
 */
TEST_F(CollabRichBindingFixture, AHeadingDoesNotOverrideAChosenSize)
{
    binding->loadContentDelta(R"([{"insert":"Title","attributes":{"size":12}}])");
    binding->applyRemoteDelta(R"([{"retain":5,"attributes":{"header":2}}])");

    EXPECT_EQ(formatAt(0).fontPointSize(), 12);
    EXPECT_FALSE(formatAt(0).hasProperty(QTextFormat::FontSizeAdjustment));
    EXPECT_EQ(binding->selectionFormat(0, 5).value(QStringLiteral("header")).toInt(), 2);
}

/*!
 * GIVEN The caret where no word is, nothing selected
 * WHEN  A font then a size are chosen, then something typed there
 * THEN  What is typed takes both
 */
TEST_F(CollabRichBindingFixture, AFontAndASizeChosenTogetherGoToWhatIsTypedNext)
{
    binding->loadContentDelta(R"([{"insert":"hello "}])");
    binding->setFont(QStringLiteral("roboto"), 6, 6);
    binding->setFontSize(20, 6, 6);
    EXPECT_TRUE(deltas.isEmpty());
    const QVariantMap fmt = binding->selectionFormat(6, 6);
    EXPECT_EQ(fmt.value(QStringLiteral("font")).toString(), QStringLiteral("roboto"));
    EXPECT_EQ(fmt.value(QStringLiteral("size")).toDouble(), 20);

    type(6, QStringLiteral("x"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":6},{"insert":"x","attributes":{"font":"roboto","size":20}}])"));
    EXPECT_EQ(formatAt(6).fontPointSize(), 20);
}

/*!
 * GIVEN A font and a size chosen for what is typed next
 * WHEN  The formatting is cleared, with nothing selected
 * THEN  The choices are forgotten: what is typed next names neither
 */
TEST_F(CollabRichBindingFixture, ClearingFormattingWithNothingSelectedForgetsTheChoices)
{
    binding->loadContentDelta(R"([{"insert":"hello "}])");
    binding->setFont(QStringLiteral("roboto"), 6, 6);
    binding->setFontSize(20, 6, 6);
    binding->clearFormat(6, 6);

    EXPECT_TRUE(deltas.isEmpty());
    const QVariantMap fmt = binding->selectionFormat(6, 6);
    EXPECT_EQ(fmt.value(QStringLiteral("font")).toString(), QString());
    EXPECT_EQ(fmt.value(QStringLiteral("size")).toDouble(), 0);

    type(6, QStringLiteral("x"));
    EXPECT_EQ(QJsonDocument::fromJson(deltas.last().toUtf8()),
              QJsonDocument::fromJson(R"([{"retain":6},{"insert":"x"}])"));
}
