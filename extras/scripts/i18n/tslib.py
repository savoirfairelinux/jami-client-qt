#
#  Copyright (C) 2016-2026 Savoir-faire Linux Inc.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
#

"""Helpers to read and update Qt Linguist .ts translation files.

The .ts format is XML. A message looks like:

    <message>
        <location filename="../src/app/calladapter.cpp" line="193"/>
        <source>Missed call</source>
        <translation type="unfinished"></translation>
    </message>

A message is "untranslated" when its <translation> carries
type="unfinished" and holds no text. lupdate emits the empty form either as
``<translation type="unfinished"/>`` or
``<translation type="unfinished"></translation>``.

Reads go through ElementTree. Writes patch only the empty <translation>
tags in place so the rest of the file (header, locations, indentation,
already-translated messages) stays byte-for-byte identical, keeping diffs
minimal for review.
"""

import re
import xml.etree.ElementTree as ET

# Matches an empty unfinished translation tag, in either form lupdate emits.
# Plural messages (with <numerusform> children) are never empty and so are
# never matched here.
_EMPTY_TR_RE = re.compile(
    r'<translation type="unfinished"\s*/>'
    r'|<translation type="unfinished">\s*</translation>'
)

# Locale identifiers only (e.g. fr, zh_CN, zh-Hans, sr@latin, zh_CN.GB2312).
# Rejects path separators so a language value cannot be used to escape a
# directory when building file paths.
_LANG_RE = re.compile(r'[A-Za-z0-9_@.-]+')

# Qt formatting placeholders that must be preserved between source and
# translation: positional (%1..%9), localized numeric (%L1..%L9) and %n.
_PLACEHOLDER_RE = re.compile(r'%(?:L?\d|n)')


def validate_lang(lang):
    """Reject language codes that are not plain locale identifiers."""
    if not _LANG_RE.fullmatch(lang):
        raise ValueError('invalid language code: {!r}'.format(lang))
    return lang


def check_placeholders(context, source, translation):
    """Raise ValueError if the translation drops or adds a Qt placeholder.

    A mismatch (e.g. losing %1 from a string passed through arg()) breaks
    runtime formatting, so it must be caught before the string is marked
    finished.
    """
    import collections
    src = collections.Counter(_PLACEHOLDER_RE.findall(source))
    dst = collections.Counter(_PLACEHOLDER_RE.findall(translation))
    if src != dst:
        raise ValueError(
            'placeholder mismatch for ({!r}, {!r}): source has {}, '
            'translation has {}'.format(
                context, source,
                sorted(src.elements()), sorted(dst.elements())))


def has_unfinished_plural(ts_path):
    """Return [(context, source), …] for plural messages needing translation.

    Qt plural messages (numerus="yes") hold <numerusform> children rather than
    plain text, so they bypass the simple empty-translation path. The current
    tooling does not fill them; callers use this to fail loudly instead of
    silently skipping such strings. The project currently has none.
    """
    found = []
    root = ET.parse(ts_path).getroot()
    for context in root.findall('context'):
        name = context.findtext('name')
        for message in context.findall('message'):
            if message.get('numerus') != 'yes':
                continue
            translation = message.find('translation')
            if translation is None:
                continue
            forms = translation.findall('numerusform')
            unfinished = translation.get('type') == 'unfinished'
            empty_form = any(not (f.text or '').strip() for f in forms)
            if unfinished or empty_form:
                found.append((name, message.findtext('source') or ''))
    return found


def _is_empty_unfinished(translation):
    if translation is None:
        return False
    if translation.get('type') != 'unfinished':
        return False
    if len(translation):  # has child elements (e.g. numerusform)
        return False
    return not (translation.text and translation.text.strip())


def parse_untranslated(ts_path):
    """Return ordered list of {context, source} for empty unfinished messages.

    Order follows document order, matching the order of empty tags in the raw
    text, which is what apply_translations relies on for alignment.
    """
    entries = []
    root = ET.parse(ts_path).getroot()
    for context in root.findall('context'):
        name = context.findtext('name')
        for message in context.findall('message'):
            if _is_empty_unfinished(message.find('translation')):
                entries.append({'context': name,
                                'source': message.findtext('source') or ''})
    return entries


def parse_translated(ts_path):
    """Return {(context, source): text} for every finished, non-empty message.

    Useful to propagate a base language (e.g. es) into a regional variant
    (e.g. es_ES) by feeding the result to apply_translations.
    """
    result = {}
    root = ET.parse(ts_path).getroot()
    for context in root.findall('context'):
        name = context.findtext('name')
        for message in context.findall('message'):
            translation = message.find('translation')
            if translation is None or len(translation):
                continue
            if translation.get('type') == 'unfinished':
                continue
            text = translation.text or ''
            if text.strip():
                result[(name, message.findtext('source') or '')] = text
    return result


def _xml_escape(text):
    # Match the entities Qt's lupdate emits in element content so the output
    # stays canonical and future lupdate runs produce no spurious diff.
    return (text.replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;')
                .replace("'", '&apos;'))


def _patch_empty_translations(ts_path, resolver):
    """Rewrite each empty unfinished translation using ``resolver``.

    ``resolver(index, context, source)`` returns the translated string for the
    untranslated message at document position ``index``, or a falsy value to
    leave it untouched. Only the empty <translation> tags are rewritten, so the
    rest of the file stays byte-for-byte identical. Returns the applied count.

    Raises ValueError if the number of empty tags in the raw text does not match
    the parsed messages, which means the file changed unexpectedly.
    """
    empties = parse_untranslated(ts_path)

    with open(ts_path, 'r', encoding='utf-8') as handle:
        text = handle.read()

    matches = list(_EMPTY_TR_RE.finditer(text))
    if len(matches) != len(empties):
        raise ValueError(
            '{}: found {} empty translation tags but parsed {} messages; '
            'the file changed unexpectedly'.format(
                ts_path, len(matches), len(empties)))

    applied = 0
    out = []
    last = 0
    for index, (entry, match) in enumerate(zip(empties, matches)):
        value = resolver(index, entry['context'], entry['source'])
        out.append(text[last:match.start()])
        if value:
            out.append('<translation>{}</translation>'.format(
                _xml_escape(value)))
            applied += 1
        else:
            out.append(match.group(0))
        last = match.end()
    out.append(text[last:])

    if applied:
        with open(ts_path, 'w', encoding='utf-8') as handle:
            handle.write(''.join(out))
    return applied


def apply_translations(ts_path, translations):
    """Fill empty unfinished translations from a content map.

    ``translations`` maps (context, source) -> translated string; messages are
    matched by their content, so the same source always gets the same text.
    This is used to propagate a base language into a regional variant. Only
    non-empty mappings are applied. Returns the count of applied translations.
    """
    return _patch_empty_translations(
        ts_path, lambda index, ctx, src: translations.get((ctx, src)))


def apply_ordered(ts_path, entries):
    """Fill empty unfinished translations from an ordered list of entries.

    ``entries`` must be the untranslated messages in document order (as emitted
    by parse_untranslated / the export script). Each entry's context and source
    are verified against the message at the same position before its
    translation is written, so distinct messages that happen to share the same
    source text never receive each other's translation. Only entries with a
    non-empty ``translation`` are applied. Returns the count applied.

    Raises ValueError if the entries do not line up with the file, which means
    the file changed since the entries were exported.
    """
    current = parse_untranslated(ts_path)
    if len(entries) != len(current):
        raise ValueError(
            '{}: expected {} entries but found {} untranslated messages; '
            're-export after running update-translations.py'.format(
                ts_path, len(entries), len(current)))

    def resolver(index, ctx, src):
        entry = entries[index]
        if entry['context'] != ctx or entry['source'] != src:
            raise ValueError(
                '{}: entry {} does not match message ({!r}, {!r}); re-export '
                'after running update-translations.py'.format(
                    ts_path, index, ctx, src))
        value = entry.get('translation') or None
        if value:
            check_placeholders(ctx, src, value)
        return value

    return _patch_empty_translations(ts_path, resolver)
