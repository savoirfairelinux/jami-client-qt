# Document fonts

The fonts a collaborative document can name. A run of text is set in one of
them through the inline attribute `"font"`, holding one of the ids below; text
without the attribute is drawn in the editor's own font. The Android and iOS
clients ship the same files under the same ids, so the lists have to be kept
in step: an id is part of the document format.

| Id                 | Family           | Stands in for    | Version | Source |
|--------------------|------------------|------------------|---------|--------|
| `liberation-sans`  | Liberation Sans  | Arial, Helvetica | 2.1.5   | [liberation-fonts 2.1.5](https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5) |
| `liberation-serif` | Liberation Serif | Times New Roman  | 2.1.5   | [liberation-fonts 2.1.5](https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5) |
| `liberation-mono`  | Liberation Mono  | Courier New      | 2.1.5   | [liberation-fonts 2.1.5](https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5) |
| `carlito`          | Carlito          | Calibri          | 1.104   | [google/fonts `ofl/carlito`](https://github.com/google/fonts/tree/3dd78844021e/ofl/carlito) |
| `caladea`          | Caladea          | Cambria          | 1.001   | [google/fonts `ofl/caladea`](https://github.com/google/fonts/tree/13c010f76605/ofl/caladea) |
| `gelasio`          | Gelasio          | Georgia          | 1.008   | [SorkinType/Gelasio `fonts/ttf`](https://github.com/SorkinType/Gelasio/tree/2c0540285e82/fonts/ttf) |
| `eb-garamond`      | EB Garamond      | Garamond         | 1.002   | [octaviopardo/EBGaramond12 `fonts/ttf`](https://github.com/octaviopardo/EBGaramond12/tree/6d9aff51f8d0/fonts/ttf) |
| `roboto`           | Roboto           |                  | 3.016   | [roboto-3-classic v3.016](https://github.com/googlefonts/roboto-3-classic/releases/tag/v3.016), `web/static` |
| `open-sans`        | Open Sans        |                  | 3.003   | [googlefonts/opensans `fonts/ttf`](https://github.com/googlefonts/opensans/tree/bd7e37632246/fonts/ttf) |
| `comic-neue`       | Comic Neue       | Comic Sans MS    | 2.003   | [google/fonts `ofl/comicneue`](https://github.com/google/fonts/tree/3dd78844021e/ofl/comicneue) |

Each family comes as four static TrueType files: `-Regular`, `-Bold`,
`-Italic` and `-BoldItalic`.

All of them are licensed under the SIL Open Font License 1.1, which lets them
be bundled with Jami and embedded in the documents it exports. Each family's
license sits next to its files (`*-OFL.txt`, `Liberation-LICENSE.txt`).

The files are the upstream releases, unmodified, and are to be kept that way:
several of these fonts reserve their names, which a modified version -- a
subset, a conversion to another format -- may not carry.
