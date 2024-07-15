import VariantUnitManager from "js/services/variant_unit_manager";

// Javascript clone of VariantUnits::OptionValueNamer, for bulk product editing.
export default class OptionValueNamer {
  constructor(variant) {
    this.variant = variant;
    this.variantUnitManager = new VariantUnitManager();
  }

  name() {
    const [value, unit] = this.option_value_value_unit();
    const separator = this.value_scaled() ? "" : " ";
    const name_fields = [];
    if (value && unit) {
      name_fields.push(`${value}${separator}${unit}`);
    } else if (value) {
      name_fields.push(value);
    }

    if (this.variant.unit_description) {
      name_fields.push(this.variant.unit_description);
    }
    return name_fields.join(" ");
  }

  value_scaled() {
    return !!this.variant.variant_unit_scale;
  }

  option_value_value_unit() {
    let value, unit_name;
    if (this.variant.unit_value) {
      if (this.variant.variant_unit === "weight" || this.variant.variant_unit === "volume") {
        [value, unit_name] = this.option_value_value_unit_scaled();
      } else {
        value = this.variant.unit_value;
        unit_name = this.pluralize(this.variant.variant_unit_name, value);
      }
      if (value == parseInt(value, 10)) {
        value = parseInt(value, 10);
      }
    } else {
      value = unit_name = null;
    }
    return [value, unit_name];
  }

  pluralize(unit_name, count) {
    if (count == null) {
      return unit_name;
    }
    const unit_key = this.unit_key(unit_name);
    if (!unit_key) {
      return unit_name;
    }
    return I18n.t(["inflections", unit_key], {
      count: count,
      defaultValue: unit_name,
    });
  }

  unit_key(unit_name) {
    if (!I18n.unit_keys) {
      I18n.unit_keys = {};
      for (const [key, translations] of Object.entries(I18n.t("inflections"))) {
        for (const [quantifier, translation] of Object.entries(translations)) {
          I18n.unit_keys[translation.toLowerCase()] = key;
        }
      }
    }
    return I18n.unit_keys[unit_name.toLowerCase()];
  }

  option_value_value_unit_scaled() {
    const [unit_scale, unit_name] = this.scale_for_unit_value();

    const value = Math.round((this.variant.unit_value / unit_scale) * 100) / 100;
    return [value, unit_name];
  }

  scale_for_unit_value() {
    // Find the largest available and compatible unit where unit_value comes
    // to >= 1 when expressed in it.
    // If there is none available where this is true, use the smallest
    // available unit.
    const scales = this.variantUnitManager.compatibleUnitScales(
      this.variant.variant_unit_scale,
      this.variant.variant_unit,
    );
    const variantUnitValue = this.variant.unit_value;

    // sets largestScale = last element in filtered scales array
    const largestScale = scales.filter((s) => variantUnitValue / s >= 1).slice(-1)[0];
    if (largestScale) {
      return [
        largestScale,
        this.variantUnitManager.getUnitName(largestScale, this.variant.variant_unit),
      ];
    } else {
      return [scales[0], this.variantUnitManager.getUnitName(scales[0], this.variant.variant_unit)];
    }
  }
}
