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

#include <QApplication>
#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJSEngine>
#include <QMimeData>
#include <QScopeGuard>
#include <QTemporaryDir>
#include <QUrl>

class PasteFixture : public QObject, public ::testing::Test
{
    Q_OBJECT

public:
    void SetUp() override
    {
        messagesAdapter.reset(new MessagesAdapter(globalEnv.settingsManager.data(),
                                                  globalEnv.previewEngine.data(),
                                                  globalEnv.lrcInstance.data()));
    }

    void TearDown() override
    {
        messagesAdapter.reset();
        // Leave clipboard clean for subsequent tests.
        QApplication::clipboard()->clear();
    }

    std::pair<QStringList, bool> pasteClipboard(bool allowFiles = true)
    {
        QJSEngine engine;
        const auto files = engine.newArray();
        const auto acceptFile = engine.evaluate("files => path => { files.push(path); return true; }").call({files});
        const bool pasteText = messagesAdapter->pasteFromClipboard(allowFiles, acceptFile);
        QStringList filePaths;
        for (quint32 i = 0, count = files.property("length").toUInt(); i < count; ++i)
            filePaths << files.property(i).toString();
        return {filePaths, pasteText};
    }

    std::pair<QStringList, bool> pasteUrls(const QList<QUrl>& urls)
    {
        auto* mime = new QMimeData;
        mime->setUrls(urls);
        QApplication::clipboard()->setMimeData(mime);

        return pasteClipboard();
    }

    QScopedPointer<MessagesAdapter> messagesAdapter;
    QUrl openedUrl;

public Q_SLOTS:
    void recordOpenedUrl(const QUrl& url)
    {
        openedUrl = url;
    }
};

// ── MessagesAdapter::pasteFromClipboard ──────────────────────────────────────

/*!
 * WHEN  The clipboard holds a local file URL (file:///path).
 * THEN  The absolute local path is attached without pasting text.
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
 * THEN  The decoded path is attached.
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
 * THEN  Paste the URL as text, without adding an attachment.
 */
TEST_F(PasteFixture, NonLocalUrlPastesAsText)
{
    auto [files, textCount] = pasteUrls({QUrl("https://jami.net/download")});

    EXPECT_EQ(files.size(), 0);
    EXPECT_EQ(textCount, 1);
}

/*!
 * WHEN  The clipboard holds a mix of a local file and a non-local URL.
 * THEN  Attach the local file and paste the link as text.
 */
TEST_F(PasteFixture, MixedUrlsAttachFilesAndPasteText)
{
    const QString localPath = "/tmp/photo.jpg";
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(localPath), QUrl("https://jami.net")});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), localPath.toStdString());
    EXPECT_EQ(textCount, 1);
}

/*!
 * WHEN  The clipboard holds multiple local files.
 * THEN  Attach each file without pasting text.
 */
TEST_F(PasteFixture, MultipleLocalFilesAreEachAttached)
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
 * THEN  Paste the text without adding an attachment.
 */
TEST_F(PasteFixture, PlainTextPastesAsText)
{
    auto* mime = new QMimeData;
    mime->setText("hello world");
    QApplication::clipboard()->setMimeData(mime);

    auto [files, pasteText] = pasteClipboard();
    EXPECT_TRUE(files.isEmpty());
    EXPECT_TRUE(pasteText);
}

/*!
 * WHEN  Ctrl+V is pressed while the clipboard holds a local file URL.
 * THEN  Attach the absolute path without pasting text.
 */
TEST_F(PasteFixture, KeyboardPaste_LocalFileEmitsAbsolutePath)
{
    const QString path = "/home/user/report.odt";
    auto [files, textCount] = pasteUrls({QUrl::fromLocalFile(path)});

    ASSERT_EQ(files.size(), 1);
    EXPECT_EQ(files.first().toStdString(), path.toStdString());
    EXPECT_EQ(textCount, 0);
}

TEST_F(PasteFixture, EncodedGifPreservesOriginalBytes)
{
    const auto gif = QByteArray::fromBase64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7");
    auto* mime = new QMimeData;
    mime->setData("image/gif", gif);
    QApplication::clipboard()->setMimeData(mime);

    const auto [files, pasteText] = pasteClipboard();
    ASSERT_EQ(files.size(), 1);
    const auto cleanup = qScopeGuard([&] { QFile::remove(files.first()); });
    QFile file(files.first());
    ASSERT_TRUE(file.open(QIODevice::ReadOnly));
    EXPECT_EQ(file.readAll(), gif);
    EXPECT_FALSE(pasteText);

    const auto [blockedFiles, blockedText] = pasteClipboard(false);
    EXPECT_TRUE(blockedFiles.isEmpty());
    EXPECT_FALSE(blockedText);
}

TEST_F(PasteFixture, ThrowingHandlerDeclinesImage)
{
    auto* mime = new QMimeData;
    mime->setData("image/gif", QByteArray::fromBase64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"));
    QApplication::clipboard()->setMimeData(mime);

    QJSEngine engine;
    const auto offered = engine.newArray();
    const auto acceptFile = engine.evaluate("offered => path => { offered.push(path); throw new Error('closed'); }")
                                .call({offered});
    EXPECT_FALSE(messagesAdapter->pasteFromClipboard(true, acceptFile));
    ASSERT_EQ(offered.property("length").toUInt(), 1u);
    EXPECT_FALSE(QFile::exists(offered.property(0).toString()));
}

/*!
 * WHEN  A local file path contains spaces and URL-reserved characters.
 * THEN  the directory URL passed to the desktop shell is fully encoded.
 */
TEST_F(PasteFixture, OpenDirectoryEncodesReservedCharacters)
{
    QTemporaryDir tempDir;
    ASSERT_TRUE(tempDir.isValid());

    QDir dir(tempDir.path());
    ASSERT_TRUE(dir.mkpath("folder with spaces/#hash"));
    const QString filePath = dir.filePath("folder with spaces/#hash/file.txt");
    QFile file(filePath);
    ASSERT_TRUE(file.open(QIODevice::WriteOnly));
    file.close();

    QDesktopServices::setUrlHandler("file", this, "recordOpenedUrl");
    const auto resetUrlHandler = qScopeGuard([] { QDesktopServices::unsetUrlHandler("file"); });

    const QString directoryPath = QFileInfo(filePath).dir().absolutePath();
    const QString expectedUrl = QUrl::fromLocalFile(directoryPath).toString(QUrl::FullyEncoded);
    for (const auto& path :
         {filePath, QUrl::fromLocalFile(filePath).toString(QUrl::FullyEncoded), directoryPath, expectedUrl}) {
        openedUrl.clear();
        messagesAdapter->openDirectory(path);
        EXPECT_EQ(openedUrl.toString(QUrl::FullyEncoded).toStdString(), expectedUrl.toStdString());
    }
}

#include "paste_unittest.moc"
