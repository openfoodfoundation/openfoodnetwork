export default class PriceParser {
  parse(price) {
    if (!price) {
      return null;
    }

    // used decimal and thousands separators from currency configuration
    const decimalSeparator = I18n.toCurrency(0.1, { precision: 1, unit: "" }).substring(1, 2);
    const thousandsSeparator = I18n.toCurrency(1000, { precision: 1, unit: "" }).substring(1, 2);

    // Replace comma used as a decimal separator and remplace by "."
    price = this.replaceCommaByFinalPoint(price);

    // Remove configured thousands separator if it is actually a thousands separator
    price = this.removeThousandsSeparator(price, thousandsSeparator);

    if (decimalSeparator === ",") {
      price = price.replace(",", ".");
    }

    price = parseFloat(price);

    if (isNaN(price)) {
      return null;
    }

    return price;
  }

  replaceCommaByFinalPoint(price) {
    if (price.match(/^[0-9]*(,{1})[0-9]{1,2}$/g)) {
      return price.replace(",", ".");
    } else {
      return price;
    }
  }

  removeThousandsSeparator(price, thousandsSeparator) {
    if (new RegExp(`^([0-9]*(${thousandsSeparator}{1})[0-9]{3}[0-9\.,]*)*$`, "g").test(price)) {
      return price.replaceAll(thousandsSeparator, "");
    } else {
      return price;
    }
  }
}
