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
  /*
   * defaultDate (optional): "startOfDay" | "endOfDay"
   */
  static values = { enableTime: Boolean, mode: String, defaultDate: String };
  static targets = ["start", "end"];
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
    const datetimepicker = this.enableTimeValue === true;
    const mode = this.modeValue === "range" ? "range" : "single";
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
      plugins: this.plugins(mode, datetimepicker),
      mode,
    };
  }

  connect() {
    super.connect();
    window.addEventListener("flatpickr:change", this.onChangeEvent);
    window.addEventListener("flatpickr:clear", this.clear);
  }

  disconnect() {
    super.disconnect();
    window.removeEventListener("flatpickr:change", this.onChangeEvent);
    window.removeEventListener("flatpickr:clear", this.clear);
  }

  clear = (e) => {
    this.fp.setDate(null);
  };

  open() {
    this.fp.element.dispatchEvent(new Event("focus"));
    if (!this.fp.selectedDates.length) {
      this.setDefaultDateValue();
    }
  }

  onChangeEvent = (e) => {
    if (this.modeValue === "range" && this.hasStartTarget && this.hasEndTarget) {
      // date range mode
      if (e.detail) {
        this.startTarget.value = e.detail.startDate;
        this.endTarget.value = e.detail.endDate;
      }
      this.fp.setDate([this.startTarget.value, this.endTarget.value]);
    } else if (e.detail.date) {
      // single date mode
      this.fp.setDate(e.detail.date);
    }
  };

  change(selectedDates, dateStr, instance) {
    if (this.hasStartTarget && this.hasEndTarget && this.modeValue === "range") {
      this.startTarget.value = selectedDates[0]
        ? this.fp.formatDate(selectedDates[0], this.config.dateFormat)
        : "";
      this.endTarget.value = selectedDates[1]
        ? this.fp.formatDate(selectedDates[1], this.config.dateFormat)
        : "";
      // Also, send event to be sure that ng-model is well updated
      // Send event only if range il valid, ie. start and end are not empty
      if (this.startTarget.value && this.endTarget.value) {
        this.startTarget.dispatchEvent(new Event("change"));
        this.endTarget.dispatchEvent(new Event("change"));
      }
    }
  }

  close() {
    // Send a change event to the input element to trigger the ng-change
    this.hasEndTarget && this.endTarget.dispatchEvent(new Event("change"));
  }

  // private

  plugins = (mode, datetimepicker) => {
    const buttons = [{ label: Spree.translations.close }];
    if (mode === "single") {
      buttons.unshift({
        label: datetimepicker ? Spree.translations.now : Spree.translations.today,
      });
    }
    return [
      ShortcutButtonsPlugin({
        button: buttons,
        onClick: this.onClickButtons,
      }),
      labelPlugin({}),
    ];
  };

  onClickButtons = (index, fp) => {
    // Memorize index used for the 'Close' and 'Today|Now' buttons
    // it has index of 1 in case of single mode (ie. can set Today or Now date)
    // it has index of 0 in case of range mode (no Today or Now button)
    const closeButtonIndex = this.modeValue === "range" ? 0 : 1;
    const todayButtonIndex = this.modeValue === "range" ? null : 0;
    switch (index) {
      case todayButtonIndex:
        fp.setDate(new Date(), true);
        break;
      case closeButtonIndex:
        fp.close();
        break;
    }
  };

  setDefaultDateValue() {
    if (this.defaultDateValue === "startOfDay") {
      this.fp.setDate(moment().startOf("day").format());
    } else if (this.defaultDateValue === "endOfDay") {
      /*
       * We use "startOf('day')" of tomorrow in order to not lose
       * the records between [23:59:00 ~ 23:59:59] of today
       */
      this.fp.setDate(moment().add(1, "days").startOf("day").format());
    }
  }
}
