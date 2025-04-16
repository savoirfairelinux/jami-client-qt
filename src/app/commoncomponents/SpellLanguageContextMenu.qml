/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "contextmenu"
import "../mainview"
import "../mainview/components"

ContextMenuAutoLoader {
    id: root
    signal languageChanged(string language)

    CachedFile {
        id: cachedFile
    }

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: af_ZA
            canTrigger: true
            isActif: true
            itemName: JamiStrings.afrikaans
            hasIcon: false
            onClicked: {
                var language = "af_ZA/af_ZA";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: an_ES
            canTrigger: true
            isActif: true
            itemName: JamiStrings.aragonese
            hasIcon: false
            onClicked: {
                var language = "an_ES/an_ES";
                languageChanged(language);
            }
        },
        // Ajoutez les autres langues de la même manière
        GeneralMenuItem {
            id: ar
            canTrigger: true
            isActif: true
            itemName: JamiStrings.arabic
            hasIcon: false
            onClicked: {
                var language = "ar/ar";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: be_BY
            canTrigger: true
            isActif: true
            itemName: JamiStrings.belarusian
            hasIcon: false
            onClicked: {
                var language = "be_BY/be-official";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: bg_BG
            canTrigger: true
            isActif: true
            itemName: JamiStrings.bulgarian
            hasIcon: false
            onClicked: {
                var language = "bg_BG/bg_BG";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: bn_BD
            canTrigger: true
            isActif: true
            itemName: JamiStrings.bengali
            hasIcon: false
            onClicked: {
                var language = "bn_BD/bn_BD";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: bo
            canTrigger: true
            isActif: true
            itemName: JamiStrings.tibetan
            hasIcon: false
            onClicked: {
                var language = "bo/bo";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: br_FR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.breton
            hasIcon: false
            onClicked: {
                var language = "br_FR/br_FR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: bs_BA
            canTrigger: true
            isActif: true
            itemName: JamiStrings.bosnian
            hasIcon: false
            onClicked: {
                var language = "bs_BA/bs_BA";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ca
            canTrigger: true
            isActif: true
            itemName: JamiStrings.catalan
            hasIcon: false
            onClicked: {
                var language = "ca/dictionaries/ca";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ckb
            canTrigger: true
            isActif: true
            itemName: JamiStrings.kurdish_sorani
            hasIcon: false
            onClicked: {
                var language = "ckb/dictionaries/ckb";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: cs_CZ
            canTrigger: true
            isActif: true
            itemName: JamiStrings.czech
            hasIcon: false
            onClicked: {
                var language = "cs_CZ/cs_CZ";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: da_DK
            canTrigger: true
            isActif: true
            itemName: JamiStrings.danish
            hasIcon: false
            onClicked: {
                var language = "da_DK/da_DK";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: de
            canTrigger: true
            isActif: true
            itemName: JamiStrings.german
            hasIcon: false
            onClicked: {
                var language = "de/de_DE_frami";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: el_GR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.greek
            hasIcon: false
            onClicked: {
                var language = "el_GR/el_GR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: en
            canTrigger: true
            isActif: true
            itemName: JamiStrings.english
            hasIcon: false
            onClicked: {
                var language = "en/en_GB";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: eo
            canTrigger: true
            isActif: true
            itemName: JamiStrings.esperanto
            hasIcon: false
            onClicked: {
                var language = "eo/eo";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: es
            canTrigger: true
            isActif: true
            itemName: JamiStrings.spanish
            hasIcon: false
            onClicked: {
                var language = "es/es_ES";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: et_EE
            canTrigger: true
            isActif: true
            itemName: JamiStrings.estonian
            hasIcon: false
            onClicked: {
                var language = "et_EE/et_EE";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: fa_IR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.persian
            hasIcon: false
            onClicked: {
                var language = "fa_IR/fa-IR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: fr_FR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.french
            hasIcon: false
            onClicked: {
                var language = "fr_FR/fr";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: gd_GB
            canTrigger: true
            isActif: true
            itemName: JamiStrings.scottish_gaelic
            hasIcon: false
            onClicked: {
                var language = "gd_GB/gd_GB";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: gl
            canTrigger: true
            isActif: true
            itemName: JamiStrings.galician
            hasIcon: false
            onClicked: {
                var language = "gl/gl_ES";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: gu_IN
            canTrigger: true
            isActif: true
            itemName: JamiStrings.gujarati
            hasIcon: false
            onClicked: {
                var language = "gu_IN/gu_IN";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: gug
            canTrigger: true
            isActif: true
            itemName: JamiStrings.wayuu
            hasIcon: false
            onClicked: {
                var language = "gug/gug";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: he_IL
            canTrigger: true
            isActif: true
            itemName: JamiStrings.hebrew
            hasIcon: false
            onClicked: {
                var language = "he_IL/he_IL";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: hi_IN
            canTrigger: true
            isActif: true
            itemName: JamiStrings.hindi
            hasIcon: false
            onClicked: {
                var language = "hi_IN/hi_IN";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: hr_HR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.croatian
            hasIcon: false
            onClicked: {
                var language = "hr_HR/hr_HR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: hu_HU
            canTrigger: true
            isActif: true
            itemName: JamiStrings.hungarian
            hasIcon: false
            onClicked: {
                var language = "hu_HU/hu_HU";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: id
            canTrigger: true
            isActif: true
            itemName: JamiStrings.indonesian
            hasIcon: false
            onClicked: {
                var language = "id/id_ID";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: is
            canTrigger: true
            isActif: true
            itemName: JamiStrings.icelandic
            hasIcon: false
            onClicked: {
                var language = "is/is";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: it_IT
            canTrigger: true
            isActif: true
            itemName: JamiStrings.italian
            hasIcon: false
            onClicked: {
                var language = "it_IT/it_IT";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: kmr_Latn
            canTrigger: true
            isActif: true
            itemName: JamiStrings.kurdish_latin
            hasIcon: false
            onClicked: {
                var language = "kmr_Latn/kmr_Latn";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ko_KR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.korean
            hasIcon: false
            onClicked: {
                var language = "ko_KR/ko_KR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: lo_LA
            canTrigger: true
            isActif: true
            itemName: JamiStrings.lao
            hasIcon: false
            onClicked: {
                var language = "lo_LA/lo_LA";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: lt_LT
            canTrigger: true
            isActif: true
            itemName: JamiStrings.lithuanian
            hasIcon: false
            onClicked: {
                var language = "lt_LT/lt";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: lv_LV
            canTrigger: true
            isActif: true
            itemName: JamiStrings.latvian
            hasIcon: false
            onClicked: {
                var language = "lv_LV/lv_LV";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: mn_MN
            canTrigger: true
            isActif: true
            itemName: JamiStrings.mongolian
            hasIcon: false
            onClicked: {
                var language = "mn_MN/mn_MN";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ne_NP
            canTrigger: true
            isActif: true
            itemName: JamiStrings.nepali
            hasIcon: false
            onClicked: {
                var language = "ne_NP/ne_NP";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: nl_NL
            canTrigger: true
            isActif: true
            itemName: JamiStrings.dutch
            hasIcon: false
            onClicked: {
                var language = "nl_NL/nl_NL";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: no
            canTrigger: true
            isActif: true
            itemName: JamiStrings.norwegian
            hasIcon: false
            onClicked: {
                var language = "no/nb_NO";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: oc_FR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.occitan
            hasIcon: false
            onClicked: {
                var language = "oc_FR/oc_FR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: pl_PL
            canTrigger: true
            isActif: true
            itemName: JamiStrings.polish
            hasIcon: false
            onClicked: {
                var language = "pl_PL/pl_PL";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: pt_BR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.portuguese_brazil
            hasIcon: false
            onClicked: {
                var language = "pt_BR/pt_BR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: pt_PT
            canTrigger: true
            isActif: true
            itemName: JamiStrings.portuguese_portugal
            hasIcon: false
            onClicked: {
                var language = "pt_PT/pt_PT";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ro
            canTrigger: true
            isActif: true
            itemName: JamiStrings.romanian
            hasIcon: false
            onClicked: {
                var language = "ro/ro_RO";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: ru_RU
            canTrigger: true
            isActif: true
            itemName: JamiStrings.russian
            hasIcon: false
            onClicked: {
                var language = "ru_RU/ru_RU";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: si_LK
            canTrigger: true
            isActif: true
            itemName: JamiStrings.sinhala
            hasIcon: false
            onClicked: {
                var language = "si_LK/si_LK";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sk_SK
            canTrigger: true
            isActif: true
            itemName: JamiStrings.slovak
            hasIcon: false
            onClicked: {
                var language = "sk_SK/sk_SK";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sl_SI
            canTrigger: true
            isActif: true
            itemName: JamiStrings.slovenian
            hasIcon: false
            onClicked: {
                var language = "sl_SI/sl_SI";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sq_AL
            canTrigger: true
            isActif: true
            itemName: JamiStrings.albanian
            hasIcon: false
            onClicked: {
                var language = "sq_AL/sq_AL";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sr
            canTrigger: true
            isActif: true
            itemName: JamiStrings.serbian
            hasIcon: false
            onClicked: {
                var language = "sr/sr";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sv_SE
            canTrigger: true
            isActif: true
            itemName: JamiStrings.swedish
            hasIcon: false
            onClicked: {
                var language = "sv_SE/sv_SE";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: sw_TZ
            canTrigger: true
            isActif: true
            itemName: JamiStrings.swahili
            hasIcon: false
            onClicked: {
                var language = "sw_TZ/sw_TZ";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: te_IN
            canTrigger: true
            isActif: true
            itemName: JamiStrings.telugu
            hasIcon: false
            onClicked: {
                var language = "te_IN/te_IN";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: th_TH
            canTrigger: true
            isActif: true
            itemName: JamiStrings.thai
            hasIcon: false
            onClicked: {
                var language = "th_TH/th_TH";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: tr_TR
            canTrigger: true
            isActif: true
            itemName: JamiStrings.turkish
            hasIcon: false
            onClicked: {
                var language = "tr_TR/tr_TR";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: uk_UA
            canTrigger: true
            isActif: true
            itemName: JamiStrings.ukrainian
            hasIcon: false
            onClicked: {
                var language = "uk_UA/uk_UA";
                languageChanged(language);
            }
        },
        GeneralMenuItem {
            id: vi
            canTrigger: true
            isActif: true
            itemName: JamiStrings.vietnamese
            hasIcon: false
            onClicked: {
                var language = "vi/vi_VN";
                languageChanged(language);
            }
        }
        // aff file is missing for this language need to figure it out
        //GeneralMenuItem {
        //    id: zu_ZA
        //    canTrigger: true
        //    isActif: true
        //    itemName: JamiStrings.zulu
        //    hasIcon: false
        //    onClicked: {
        //        var language = "zu_ZA"
        //        languageChanged(language)
        //    }
        //}


    ]

    function openMenuAt(mouseEvent) {
        x = mouseEvent.x;
        y = mouseEvent.y;
        root.openMenu();
    }

    Component.onCompleted: menuItemsToLoad = menuItems
}
