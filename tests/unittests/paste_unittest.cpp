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

#include "messagesadapter.h"
#include "utilsadapter.h"
#include "systemtray.h"

#include <QApplication>
#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMimeData>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QUrl>

class PasteFixture : public ::testing::Test
{
public:
    void SetUp() override
    {
        messagesAdapter.reset(new MessagesAdapter(globalEnv.settingsManager.data(),
                                                  globalEnv.previewEngine.data(),
                                                  globalEnv.lrcInstance.data()));
        utilsAdapter.reset(new UtilsAdapter(globalEnv.settingsManager.data(),
                                            globalEnv.systemTray.data(),
                                            globalEnv.lrcInstance.data()));
    }

    void TearDown() override
    {
        messagesAdapter.reset();
        utilsAdapter.reset();
        // Leave clipboard clean for subsequent tests.
        QApplication::clipboard()->clear();
    }

    // Puts a list of URLs into the clipboard and calls onPaste().
    // Returns {newFilePasted paths, newTextPasted count}.
    std::pair<QStringList, int> pasteUrls(const QList<QUrl>& urls)
    {
        auto* mime = new QMimeData;
        mime->setUrls(urls);
        QApplication::clipboard()->setMimeData(mime);

        QSignalSpy fileSpy(messagesAdapter.data(), &MessagesAdapter::newFilePasted);
        QSignalSpy textSpy(messagesAdapter.data(), &MessagesAdapter::newTextPasted);

        messagesAdapter->onPaste();

        QStringList filePaths;
        for (int i = 0; i < fileSpy.count(); ++i)
            filePaths << fileSpy.at(i).at(0).toString();
        return {filePaths, textSpy.count()};
    }

    QScopedPointer<MessagesAdapter> messagesAdapter;
    QScopedPointer<UtilsAdapter> utilsAdapter;
};

// ── MessagesAdapter::onPaste ──────────────────────────────────────────────────

/*!
 * WHEN  The clipboard holds a local file URL (file:///path).
 * THEN  newFilePasted is emitted with the absolute local path and
 *       newTextPasted is NOT emitted.
 *
 * This is the regression test for the old regex that stripped the leading
 * slash ("file:///home/user/doc.pdf" → "home/user/doc.pdf").
 */
TEST_F(PasteFixture, LocalFileUrlEmitsAbsolutePath)
{
    const QString path = "/home/user/document.pdf";
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(path)});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), path.toStdString());
    EXPECT_EQ(textCount, 0);
}

/*!
 * WHEN  The clipboard holds a local file URL with percent-encoded characters.
 * THEN  newFilePasted is emitted with the decoded path.
 *
 * The old regex operated on the raw URL string and could not handle
 * percent-encoding; QUrl::toLocalFile() decodes it correctly.
 */
TEST_F(PasteFixture, PercentEncodedLocalFileUrlIsDecoded)
{
    const QString decodedPath = "/tmp/my file (copy).png";
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(decodedPath)});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), decodedPath.toStdString());
    EXPECT_EQ(textCount, 0);
}

/*!
 * WHEN  The clipboard holds only a non-local URL (e.g. a web link).
 * THEN  newFilePasted is NOT emitted and newTextPasted IS emitted once
 *       so the URL text is not silently dropped.
 */
TEST_F(PasteFixture, NonLocalUrlEmitsNewTextPasted)
{
    auto [files, textCount] = pasteUrls({QUrl("https://jami.net/download")});

    EXPECT_EQ(files.size(), 0);
    EXPECT_EQ(textCount, 1);
}

/*!
 * WHEN  The clipboard holds a mix of a local file and a non-local URL.
 * THEN  newFilePasted is emitted for the local file AND newTextPasted is
 *       emitted for the non-local URL.
 */
TEST_F(PasteFixture, MixedUrlsEmitBothSignals)
{
    const QString localPath = "/tmp/photo.jpg";
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(localPath),
                                         QUrl("https://jami.net")});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), localPath.toStdString());
    EXPECT_EQ(textCount, 1);
}

/*!
 * WHEN  The clipboard holds multiple local files.
 * THEN  newFilePasted is emitted once per file and newTextPasted is NOT emitted.
 */
TEST_F(PasteFixture, MultipleLocalFilesEachEmitNewFilePasted)
{
    const QStringList paths = {"/tmp/a.txt", "/tmp/b.txt", "/tmp/c.txt"};
    QList<QUrl> urls;
    for (const auto& p : paths)
        urls << QUrl::fromLocalFile(p);

    auto [files, textCount] = pasteUrls(urls);

    ASSERT_EQ(files.size(), 3);
    for (int i = 0; i < 3; ++i)
        EXPECT_EQ(files.at(i).toStdString(), paths.at(i).toStdString());
    EXPECT_EQ(textCount, 0);
}

/*!
 * WHEN  The clipboard holds plain text (no URLs, no image).
 * THEN  newFilePasted is NOT emitted and newTextPasted IS emitted once.
 */
TEST_F(PasteFixture, PlainTextEmitsNewTextPasted)
{
    auto* mime = new QMimeData;
    mime->setText("hello world");
    QApplication::clipboard()->setMimeData(mime);

    QSignalSpy fileSpy(messagesAdapter.data(), &MessagesAdapter::newFilePasted);
    QSignalSpy textSpy(messagesAdapter.data(), &MessagesAdapter::newTextPasted);

    messagesAdapter->onPaste();

    EXPECT_EQ(fileSpy.count(), 0);
    EXPECT_EQ(textSpy.count(), 1);
}

/*!
 * Keyboard paste (Ctrl+V / Cmd+V) routes through MessagesAdapter::onPaste()
 * via QML Keys.onPressed → StandardKey.Paste.  The signal behaviour is
 * therefore identical; this test documents that the same path is taken and
 * acts as a labelled regression anchor for keyboard-triggered paste.
 *
 * WHEN  Ctrl+V is pressed while the clipboard holds a local file URL.
 * THEN  newFilePasted is emitted with the correct absolute path and
 *       newTextPasted is NOT emitted.
 */
TEST_F(PasteFixture, KeyboardPaste_LocalFileEmitsAbsolutePath)
{
    const QString path = "/home/user/report.odt";
    // Keyboard paste calls MessagesAdapter::onPaste() — exercise that path.
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(path)});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), path.toStdString());
    EXPECT_EQ(textCount, 0);
}

// ── UtilsAdapter::clipboardHasImageOrUrls ────────────────────────────────────

/*!
 * WHEN  The clipboard holds a local file URL.
 * THEN  clipboardHasImageOrUrls() returns true, enabling the Paste menu entry.
 */
TEST_F(PasteFixture, ClipboardHasImageOrUrls_TrueForLocalFileUrl)
{
    auto* mime = new QMimeData;
    mime->setUrls({QUrl::fromLocalFile("/tmp/file.txt")});
    QApplication::clipboard()->setMimeData(mime);

    EXPECT_TRUE(utilsAdapter->clipboardHasImageOrUrls());
}

/*!
 * WHEN  The clipboard holds only plain text.
 * THEN  clipboardHasImageOrUrls() returns false (text-only paste uses
 *       canPaste from TextEdit, not the custom paste path).
 */
TEST_F(PasteFixture, ClipboardHasImageOrUrls_FalseForPlainText)
{
    auto* mime = new QMimeData;
    mime->setText("some text");
    QApplication::clipboard()->setMimeData(mime);

    EXPECT_FALSE(utilsAdapter->clipboardHasImageOrUrls());
}

/*!
 * WHEN  The clipboard holds a non-local (web) URL.
 * THEN  clipboardHasImageOrUrls() returns true because the URL list is
 *       non-empty and may contain something worth pasting.
 */
TEST_F(PasteFixture, ClipboardHasImageOrUrls_TrueForWebUrl)
{
    auto* mime = new QMimeData;
    mime->setUrls({QUrl("https://jami.net")});
    QApplication::clipboard()->setMimeData(mime);

    EXPECT_TRUE(utilsAdapter->clipboardHasImageOrUrls());
}

// ── MessagesAdapter::openDirectory ────────────────────────────────────────────

/*!
 * WHEN  A local file path contains spaces and URL-reserved characters.
 * THEN  the directory URL passed to the desktop shell is fully encoded.
 */
TEST_F(PasteFixture, LocalDirectoryUrlEncodesReservedCharacters)
{
    QTemporaryDir tempDir;
    ASSERT_TRUE(tempDir.isValid());

    QDir dir(tempDir.path());
    ASSERT_TRUE(dir.mkpath("folder with spaces/#hash"));
    const QString filePath = dir.filePath("folder with spaces/#hash/file.txt");
    QFile file(filePath);
    ASSERT_TRUE(file.open(QIODevice::WriteOnly));
    file.close();

    const auto url = MessagesAdapter::localDirectoryUrl(filePath);

    EXPECT_EQ(url.toStdString(),
              QUrl::fromLocalFile(QFileInfo(filePath).dir().absolutePath())
                  .toString(QUrl::FullyEncoded)
                  .toStdString());
    EXPECT_TRUE(url.contains("%20"));
    EXPECT_TRUE(url.contains("%23hash"));
}
