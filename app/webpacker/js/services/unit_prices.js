import PriceParser from "js/services/price_parser";
import VariantUnitManager from "js/services/variant_unit_manager";
import localizeCurrency from "js/services/localize_currency";

export default class UnitPrices {
  constructor() {
    this.variantUnitManager = new VariantUnitManager();
    this.priceParser = new PriceParser();
  }

  displayableUnitPrice(price, scale, unit_type, unit_value, variant_unit_name) {
    price = this.priceParser.parse(price);
    if (price && !isNaN(price) && unit_type && unit_value) {
      const value = localizeCurrency(
        this.price(price, scale, unit_type, unit_value, variant_unit_name),
      );
      const unit = this.unit(scale, unit_type, variant_unit_name);
      return `${value} / ${unit}`;
    }
    return null;
  }

  price(price, scale, unit_type, unit_value) {
    return price / this.denominator(scale, unit_type, unit_value);
  }

  denominator(scale, unit_type, unit_value) {
    const unit = this.unit(scale, unit_type);
    if (unit === "lb") {
      return unit_value / 453.6;
    } else if (unit === "kg") {
      return unit_value / 1000;
    } else {
      return unit_value;
    }
  }

  unit(scale, unit_type, variant_unit_name = "") {
    if (variant_unit_name.length > 0 && unit_type === "items") {
      return variant_unit_name;
    } else if (unit_type === "items") {
      return "item";
    } else if (this.variantUnitManager.systemOfMeasurement(scale, unit_type) === "imperial") {
      return "lb";
    } else if (unit_type === "weight") {
      return "kg";
    } else if (unit_type === "volume") {
      return "L";
    }
  }
}
