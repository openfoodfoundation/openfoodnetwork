// import Flatpickr
import Flatpickr from "stimulus-flatpickr";
import { ar } from "flatpickr/dist/l10n/ar";
import { cat } from "flatpickr/dist/l10n/cat";
import { cy } from "flatpickr/dist/l10n/cy";
import { de } from "flatpickr/dist/l10n/de";
import { fr } from "flatpickr/dist/l10n/fr";
import { it } from "flatpickr/dist/l10n/it";
import { nl } from "flatpickr/dist/l10n/nl";
import { pl } from "flatpickr/dist/l10n/pl";
import { pt } from "flatpickr/dist/l10n/pt";
import { ru } from "flatpickr/dist/l10n/ru";
import { sv } from "flatpickr/dist/l10n/sv";
import { tr } from "flatpickr/dist/l10n/tr";
import { en } from "flatpickr/dist/l10n/default.js";
import ShortcutButtonsPlugin from "shortcut-buttons-flatpickr";
import labelPlugin from "flatpickr/dist/plugins/labelPlugin/labelPlugin";

export default class extends Flatpickr {
  static values = { enableTime: Boolean };
  locales = {
    ar: ar,
    cat: cat,
    cy: cy,
    de: de,
    fr: fr,
    it: it,
    nl: nl,
    pl: pl,
    pt: pt,
    ru: ru,
    sv: sv,
    tr: tr,
    en: en,
  };

  initialize() {
    const datetimepicker = this.enableTimeValue == true;
    // sets your language (you can also set some global setting for all time pickers)
    this.config = {
      altInput: true,
      altFormat: datetimepicker
        ? Spree.translations.flatpickr_datetime_format
        : Spree.translations.flatpickr_date_format,
      dateFormat: datetimepicker ? "Y-m-d H:i" : "Y-m-d",
      enableTime: datetimepicker,
      time_24hr: datetimepicker,
      locale: I18n.base_locale,
      plugins: [
        ShortcutButtonsPlugin({
          button: [
            {
              label: datetimepicker
                ? Spree.translations.now
                : Spree.translations.today,
            },
            {
              label: Spree.translations.close,
            },
          ],
          label: "or",
          onClick: this.onClickButtons,
        }),
        labelPlugin({}),
      ],
    };
  }

  clear(e) {
    this.fp.setDate(null);
  }

  // private

  onClickButtons = (index, fp) => {
    let date;
    // Memorize index used for the 'Close' button
    // (currently it has index of 1)
    const closeButtonIndex = 1;
    switch (index) {
      case 0:
        date = new Date();
        break;
      case closeButtonIndex:
        fp.close();
        break;
    }
    // Set the date unless clicked button was the 'Close' one
    if (index != closeButtonIndex) {
      fp.setDate(date, true);
    }
  };
}
