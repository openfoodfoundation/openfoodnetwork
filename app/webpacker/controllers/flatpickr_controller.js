// import Flatpickr
import Flatpickr from "stimulus-flatpickr";

export default class extends Flatpickr {
  static values = { enableTime: Boolean };

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
