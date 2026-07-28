/*
 *  Copyright (C) 2004-2026 Savoir-faire Linux Inc.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
#include "yrsdocument.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QString>

#include <algorithm>
#include <mutex>
#include <string_view>

// libyrs.h is a plain C header with no extern "C" guard of its own.
extern "C" {
#include <libyrs.h>
}

namespace collab {

namespace {

// Number of UTF-16 code units in a UTF-8 string (a code point above U+FFFF maps
// to a surrogate pair, i.e. 2 units). Matches Y_OFFSET_UTF16 indexing.
uint32_t
utf16Len(const std::string& utf8)
{
    uint32_t units = 0;
    for (size_t i = 0; i < utf8.size();) {
        unsigned char c = static_cast<unsigned char>(utf8[i]);
        size_t adv = c < 0x80 ? 1 : (c >> 5) == 0x6 ? 2 : (c >> 4) == 0xe ? 3 : (c >> 3) == 0x1e ? 4 : 1;
        units += (adv == 4) ? 2 : 1;
        i += adv;
    }
    return units;
}

/// Whether @p json is a JSON object yinput_json() will accept.
///
/// This is not belt and braces: yinput_json() parses with serde_json and
/// unwraps the result, so handing it anything malformed panics inside Rust and
/// takes the whole process down. Verified by running it. Every call below is
/// therefore guarded, and the op is applied without its attributes rather than
/// killing the client.
bool
isJsonObject(const std::string& json)
{
    if (json.empty())
        return false;
    const auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(json));
    return doc.isObject();
}

// Compact (no-indent) JSON serialization, used for the per-op attribute objects
// and the whole-document delta.
std::string
toCompactJson(const QJsonValue& v)
{
    QJsonDocument doc;
    if (v.isArray())
        doc = QJsonDocument(v.toArray());
    else
        doc = QJsonDocument(v.toObject());
    return doc.toJson(QJsonDocument::Compact).trimmed().toStdString();
}

QJsonValue
yOutputToJson(const YOutput& o)
{
    switch (o.tag) {
    case Y_JSON_BOOL: {
        const uint8_t* b = youtput_read_bool(&o);
        return QJsonValue(b && *b != 0);
    }
    case Y_JSON_INT: {
        const int64_t* v = youtput_read_long(&o);
        return QJsonValue(static_cast<qint64>(v ? *v : 0));
    }
    case Y_JSON_NUM: {
        const double* v = youtput_read_float(&o);
        return QJsonValue(v ? *v : 0.0);
    }
    case Y_JSON_STR: {
        char* s = youtput_read_string(&o);
        return QJsonValue(QString::fromUtf8(s ? s : ""));
    }
    default:
        return QJsonValue(QJsonValue::Null);
    }
}

// Serialize a list of formatting attributes (from a delta op) to a compact JSON
// object string. Returns an empty string when there are none.
std::string
deltaAttrsToJson(const YDeltaAttr* attrs, uint32_t len)
{
    if (!attrs || len == 0)
        return {};
    QJsonObject obj;
    for (uint32_t i = 0; i < len; ++i)
        obj.insert(QString::fromUtf8(attrs[i].key), yOutputToJson(attrs[i].value));
    return toCompactJson(obj);
}

} // namespace

std::string
YrsDocument::richOpsToDeltaJson(const std::vector<RichOp>& ops)
{
    QJsonArray arr;
    for (const auto& op : ops) {
        QJsonObject o;
        switch (op.kind) {
        case RichOp::Kind::Retain:
            o[QStringLiteral("retain")] = static_cast<qint64>(op.len);
            break;
        case RichOp::Kind::Delete:
            o[QStringLiteral("delete")] = static_cast<qint64>(op.len);
            break;
        case RichOp::Kind::Insert:
            o[QStringLiteral("insert")] = QString::fromStdString(op.text);
            break;
        }
        if (!op.attrs.empty()) {
            const auto attrs = QJsonDocument::fromJson(QByteArray::fromStdString(op.attrs));
            if (attrs.isObject())
                o[QStringLiteral("attributes")] = attrs.object();
        }
        arr.append(o);
    }
    return toCompactJson(QJsonValue(arr));
}

std::vector<YrsDocument::RichOp>
YrsDocument::deltaJsonToRichOps(const std::string& deltaJson)
{
    std::vector<RichOp> ops;
    const auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(deltaJson));
    if (!doc.isArray())
        return ops;
    for (const auto& value : doc.array()) {
        if (!value.isObject())
            continue;
        const auto o = value.toObject();
        RichOp op;
        if (o.value(QStringLiteral("insert")).isString()) {
            op.kind = RichOp::Kind::Insert;
            op.text = o.value(QStringLiteral("insert")).toString().toStdString();
        } else if (o.value(QStringLiteral("retain")).isDouble()) {
            op.kind = RichOp::Kind::Retain;
            op.len = static_cast<uint32_t>(o.value(QStringLiteral("retain")).toInt());
        } else if (o.value(QStringLiteral("delete")).isDouble()) {
            op.kind = RichOp::Kind::Delete;
            op.len = static_cast<uint32_t>(o.value(QStringLiteral("delete")).toInt());
        } else {
            continue;
        }
        if (o.value(QStringLiteral("attributes")).isObject())
            op.attrs = toCompactJson(o.value(QStringLiteral("attributes")));
        ops.push_back(std::move(op));
    }
    return ops;
}

struct YrsDocument::Impl
{
    YDoc* doc {nullptr};
    Branch* text {nullptr};
    YSubscription* updateSub {nullptr};
    YSubscription* textSub {nullptr};

    UpdateCallback updateCb;
    ChangeCallback changeCb;
    RichChangeCallback richChangeCb;

    std::recursive_mutex mutex;
    // True while applyUpdate() is running, so the observe callbacks can tell a
    // remote mutation from a local insert()/remove().
    bool applyingRemote {false};
    // True while seeding a document from persisted commits: the observe callbacks
    // suppress all client notifications, since the caller reads the converged state
    // directly once loading completes.
    bool suppressEmit {false};

    static void onUpdate(void* state, uint32_t len, const char* data)
    {
        auto* self = static_cast<Impl*>(state);
        if (self->suppressEmit)
            return;
        if (self->updateCb && len > 0) {
            Bytes update(reinterpret_cast<const uint8_t*>(data), reinterpret_cast<const uint8_t*>(data) + len);
            self->updateCb(update, !self->applyingRemote);
        }
    }

    static void onChange(void* state, const YTextEvent* event)
    {
        auto* self = static_cast<Impl*>(state);
        if (self->suppressEmit)
            return;
        if (!self->changeCb && !self->richChangeCb)
            return;
        uint32_t n = 0;
        YDeltaOut* delta = ytext_event_delta(event, &n);
        std::vector<TextChange> changes;
        std::vector<RichOp> richOps;
        uint32_t pos = 0;
        for (uint32_t i = 0; i < n; ++i) {
            std::string attrs = deltaAttrsToJson(delta[i].attributes, delta[i].attributes_len);
            switch (delta[i].tag) {
            case Y_EVENT_CHANGE_RETAIN:
                pos += delta[i].len;
                richOps.push_back({RichOp::Kind::Retain, delta[i].len, std::string {}, attrs});
                break;
            case Y_EVENT_CHANGE_DELETE:
                changes.push_back({pos, delta[i].len, std::string {}});
                richOps.push_back({RichOp::Kind::Delete, delta[i].len, std::string {}, std::string {}});
                break;
            case Y_EVENT_CHANGE_ADD: {
                char* str = youtput_read_string(delta[i].insert);
                std::string text = str ? std::string {str} : std::string {};
                changes.push_back({pos, 0, text});
                richOps.push_back({RichOp::Kind::Insert, delta[i].len, text, attrs});
                // In UTF-16 offset mode, len is the inserted code unit count.
                pos += delta[i].len;
                break;
            }
            default:
                break;
            }
        }
        ytext_delta_destroy(delta, n);
        if (self->changeCb && !changes.empty())
            self->changeCb(changes, !self->applyingRemote);
        if (self->richChangeCb && !richOps.empty())
            self->richChangeCb(richOps, !self->applyingRemote);
    }
};

YrsDocument::YrsDocument(uint64_t clientId)
    : pimpl_(std::make_unique<Impl>())
{
    YOptions options = yoptions();
    options.id = clientId;
    options.flags = Y_OFFSET_UTF16; // UTF-16 offsets to match the clients' editors
    pimpl_->doc = ydoc_new_with_options(options);
    // yoptions() hands over ownership of the strings it allocates (guid, and
    // collection_id when set), and ydoc_new_with_options() copies them rather
    // than adopting them. Without this, every document ever opened leaks its
    // guid for the lifetime of the process.
    if (options.guid)
        ystring_destroy(const_cast<char*>(options.guid));
    if (options.collection_id)
        ystring_destroy(const_cast<char*>(options.collection_id));
    pimpl_->text = ytext(pimpl_->doc, "content");
    pimpl_->updateSub = ydoc_observe_updates_v1(pimpl_->doc, pimpl_.get(), &Impl::onUpdate);
    pimpl_->textSub = ytext_observe(pimpl_->text, pimpl_.get(), &Impl::onChange);
}

YrsDocument::~YrsDocument()
{
    if (pimpl_->updateSub)
        yunobserve(pimpl_->updateSub);
    if (pimpl_->textSub)
        yunobserve(pimpl_->textSub);
    if (pimpl_->doc)
        ydoc_destroy(pimpl_->doc);
}

void
YrsDocument::setUpdateCallback(UpdateCallback cb)
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    pimpl_->updateCb = std::move(cb);
}

void
YrsDocument::setChangeCallback(ChangeCallback cb)
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    pimpl_->changeCb = std::move(cb);
}

void
YrsDocument::setRichChangeCallback(RichChangeCallback cb)
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    pimpl_->richChangeCb = std::move(cb);
}

void
YrsDocument::applyDelta(const std::vector<RichOp>& ops)
{
    if (ops.empty())
        return;
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_write_transaction(pimpl_->doc, 0, nullptr);
    uint32_t index = 0;
    for (const auto& op : ops) {
        // Clamp every offset/length to the live document length. yrs panics (and
        // aborts the whole process) on an out-of-range index, so this is a hard
        // safety net against any client/CRDT desync.
        uint32_t len = ytext_len(pimpl_->text, txn);
        if (index > len)
            index = len;
        switch (op.kind) {
        case RichOp::Kind::Retain: {
            uint32_t n = std::min(op.len, len - index);
            if (isJsonObject(op.attrs) && n > 0) {
                YInput attr = yinput_json(op.attrs.c_str());
                ytext_format(pimpl_->text, txn, index, n, &attr);
            }
            index += op.len;
            break;
        }
        case RichOp::Kind::Insert: {
            if (!op.text.empty()) {
                if (!isJsonObject(op.attrs)) {
                    ytext_insert(pimpl_->text, txn, index, op.text.c_str(), nullptr);
                } else {
                    YInput attr = yinput_json(op.attrs.c_str());
                    ytext_insert(pimpl_->text, txn, index, op.text.c_str(), &attr);
                }
                index += utf16Len(op.text);
            }
            break;
        }
        case RichOp::Kind::Delete: {
            uint32_t n = std::min(op.len, len - index);
            if (n > 0)
                ytext_remove_range(pimpl_->text, txn, index, n);
            break;
        }
        }
    }
    ytransaction_commit(txn);
}

std::string
YrsDocument::contentDelta() const
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_read_transaction(pimpl_->doc);
    uint32_t n = 0;
    YChunk* chunks = ytext_chunks(pimpl_->text, txn, &n);
    QJsonArray arr;
    for (uint32_t i = 0; i < n; ++i) {
        char* s = youtput_read_string(&chunks[i].data);
        QJsonObject op;
        op.insert("insert", QString::fromUtf8(s ? s : ""));
        if (chunks[i].fmt_len > 0) {
            QJsonObject attrs;
            for (uint32_t j = 0; j < chunks[i].fmt_len; ++j) {
                const auto& entry = chunks[i].fmt[j];
                attrs.insert(QString::fromUtf8(entry.key),
                             entry.value ? yOutputToJson(*entry.value) : QJsonValue(QJsonValue::Null));
            }
            op.insert("attributes", attrs);
        }
        arr.append(op);
    }
    if (chunks)
        ychunks_destroy(chunks, n);
    ytransaction_commit(txn);
    return toCompactJson(QJsonValue(arr));
}

void
YrsDocument::insert(uint32_t index, const std::string& utf8Text)
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_write_transaction(pimpl_->doc, 0, nullptr);
    // yrs panics on an out-of-range index, and a panic in the engine aborts the
    // whole client. The caller's view of the length can legitimately lag behind
    // the document -- a remote update may have landed between the two -- so the
    // index is clamped rather than trusted.
    const uint32_t len = ytext_len(pimpl_->text, txn);
    if (index > len)
        index = len;
    ytext_insert(pimpl_->text, txn, index, utf8Text.c_str(), nullptr);
    ytransaction_commit(txn);
}

/// Number of UTF-16 code units in a UTF-8 string. Y-CRDT is configured with
/// Y_OFFSET_UTF16, so every index handed to the document is counted this way.
static uint32_t
utf16Length(std::string_view utf8)
{
    uint32_t units = 0;
    for (size_t i = 0; i < utf8.size();) {
        const auto c = static_cast<unsigned char>(utf8[i]);
        if (c < 0x80) {
            i += 1;
            units += 1;
        } else if ((c >> 5) == 0x6) {
            i += 2;
            units += 1;
        } else if ((c >> 4) == 0xE) {
            i += 3;
            units += 1;
        } else if ((c >> 3) == 0x1E) {
            i += 4;
            units += 2; // beyond the BMP: encoded as a surrogate pair
        } else {
            i += 1; // stray byte, keep walking rather than looping forever
            units += 1;
        }
    }
    return units;
}

/// Whether @c c continues a UTF-8 sequence rather than starting one.
static bool
isContinuation(char c)
{
    return (static_cast<unsigned char>(c) & 0xC0) == 0x80;
}

/// The smallest single splice turning @c from into @c to, as UTF-16 offsets.
/// Restoring by replacing everything would move every collaborator's cursor to
/// the start and produce a needlessly large update, so only the differing middle
/// is rewritten. Returns false when the texts are already identical.
static bool
textSplice(const std::string& from, const std::string& to, uint32_t& index, uint32_t& deleteLen, std::string& insert)
{
    if (from == to)
        return false;
    const size_t maxCommon = std::min(from.size(), to.size());
    size_t prefix = 0;
    while (prefix < maxCommon && from[prefix] == to[prefix])
        ++prefix;
    // Never cut inside a code point: back up to the start of the sequence.
    while (prefix > 0 && prefix < from.size() && isContinuation(from[prefix]))
        --prefix;

    size_t suffix = 0;
    const size_t maxSuffix = maxCommon - prefix;
    while (suffix < maxSuffix && from[from.size() - 1 - suffix] == to[to.size() - 1 - suffix])
        ++suffix;
    while (suffix > 0 && isContinuation(from[from.size() - suffix]))
        --suffix;

    index = utf16Length(std::string_view(from.data(), prefix));
    deleteLen = utf16Length(std::string_view(from.data() + prefix, from.size() - prefix - suffix));
    insert.assign(to, prefix, to.size() - prefix - suffix);
    return true;
}

void
YrsDocument::remove(uint32_t index, uint32_t length)
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_write_transaction(pimpl_->doc, 0, nullptr);
    // Same reason as insert(): an out-of-range range aborts the process.
    const uint32_t len = ytext_len(pimpl_->text, txn);
    if (index > len)
        index = len;
    length = std::min(length, len - index);
    if (length > 0)
        ytext_remove_range(pimpl_->text, txn, index, length);
    ytransaction_commit(txn);
}

bool
YrsDocument::spliceTo(const std::string& target)
{
    // Held across the read and the write, so no other thread can edit the text
    // between measuring the difference and rewriting it.
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);

    std::string current;
    {
        YTransaction* rtxn = ydoc_read_transaction(pimpl_->doc);
        if (!rtxn)
            return false;
        char* str = ytext_string(pimpl_->text, rtxn);
        if (str) {
            current = str;
            ystring_destroy(str);
        }
        ytransaction_commit(rtxn);
    }

    uint32_t index = 0, deleteLen = 0;
    std::string inserted;
    if (!textSplice(current, target, index, deleteLen, inserted))
        return false;

    // One transaction, so peers and observers see the replacement as a single
    // change rather than a removal briefly exposing a truncated document.
    YTransaction* txn = ydoc_write_transaction(pimpl_->doc, 0, nullptr);
    if (deleteLen > 0)
        ytext_remove_range(pimpl_->text, txn, index, deleteLen);
    if (!inserted.empty())
        ytext_insert(pimpl_->text, txn, index, inserted.c_str(), nullptr);
    ytransaction_commit(txn);
    return true;
}

bool
YrsDocument::applyUpdate(const Bytes& update, bool silent)
{
    if (update.empty())
        return false;
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    pimpl_->applyingRemote = true;
    pimpl_->suppressEmit = silent;
    YTransaction* txn = ydoc_write_transaction(pimpl_->doc, 0, nullptr);
    // A rejected update leaves the document untouched, so it costs nothing but
    // must not be reported as applied: the caller would broadcast garbage.
    auto ok = ytransaction_apply(txn, reinterpret_cast<const char*>(update.data()), update.size()) == 0;
    ytransaction_commit(txn);
    pimpl_->applyingRemote = false;
    pimpl_->suppressEmit = false;
    return ok;
}

std::string
YrsDocument::text() const
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_read_transaction(pimpl_->doc);
    char* str = ytext_string(pimpl_->text, txn);
    std::string result = str ? str : "";
    if (str)
        ystring_destroy(str);
    ytransaction_commit(txn);
    return result;
}

YrsDocument::Bytes
YrsDocument::encodeStateAsUpdate() const
{
    std::lock_guard<std::recursive_mutex> lk(pimpl_->mutex);
    YTransaction* txn = ydoc_read_transaction(pimpl_->doc);
    uint32_t len = 0;
    // A null state vector requests the full document state.
    char* data = ytransaction_state_diff_v1(txn, nullptr, 0, &len);
    Bytes update;
    if (data) {
        update.assign(reinterpret_cast<const uint8_t*>(data), reinterpret_cast<const uint8_t*>(data) + len);
        ybinary_destroy(data, len);
    }
    ytransaction_commit(txn);
    return update;
}

} // namespace collab
