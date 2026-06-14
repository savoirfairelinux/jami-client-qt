# In-house translations

Jami's Qt client keeps its localization in `translations/*.ts` (Qt Linguist
format). `jami_client_qt_en.ts` is the English source; every other file is a
target language. Translations are produced in-house — Jami no longer uses
Transifex.

## Workflow

1. **Refresh sources from the code.** Whenever user-facing strings change,
   extract them into every `.ts`:

   ```sh
   extras/scripts/update-translations.py
   ```

   This runs `lupdate` over `src/` and updates `translations/*.ts` in place
   (new strings appear as `type="unfinished"`).

2. **Export the strings still needing a translation** for one or all
   languages:

   ```sh
   cd extras/scripts/i18n
   ./export_untranslated.py --lang fr --out-dir /tmp/i18n
   ./export_untranslated.py --all   --out-dir /tmp/i18n
   ```

   Each `<lang>.json` lists the English `source` and an empty `translation`
   field to fill.

3. **Translate** by filling the `translation` fields in the JSON. Leave a
   field empty to skip it (it stays untranslated and can be exported again
   later). Keep `%1`, `%2`, … placeholders and any HTML markup intact. Do not
   reorder entries or change their `id`/`context`/`source`: the importer
   matches each entry to its message by position and verifies that identity.

4. **Import the translations back** into the `.ts` files:

   ```sh
   ./import_translations.py /tmp/i18n/fr.json
   ./import_translations.py /tmp/i18n/*.json
   ```

   Only filled fields are written; the rest of each `.ts` (header, locations,
   already-translated messages) is left untouched, so diffs stay minimal.

5. **Rebuild.** CMake compiles `translations/*.ts` to `.qm` at build time
   (`qt_add_translation`); no manual `lrelease` step is needed.

## Notes

- `import_translations.py` matches entries to messages by document position
  and verifies each entry's `context`/`source`, so it refuses to run if a
  `.ts` changed between export and import; re-run the export after any
  `update-translations.py`. The resolved `.ts` path is constrained to
  `translations/`.
- Translated text is XML-escaped to match the entities `lupdate` emits
  (`&amp; &lt; &gt; &quot; &apos;`), keeping the files canonical.
- `tslib.py` holds the shared `.ts` parsing/patching logic. `fill_from_base.py`
  matches by content (base → variant); the importer matches by position.
