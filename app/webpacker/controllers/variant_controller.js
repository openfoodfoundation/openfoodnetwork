import { Controller } from "stimulus";
import OptionValueNamer from "js/services/option_value_namer";

// Dynamically update related variant fields
//
export default class VariantController extends Controller {
  connect() {
    // Assuming these will be available on the variant soon, just a quick hack to find the product fields:
    const product = this.element.closest("[data-record-id]");
    this.variantUnit = product.querySelector('[name$="[variant_unit]"]');
    this.variantUnitScale = product.querySelector('[name$="[variant_unit_scale]"]');
    this.variantUnitName = product.querySelector('[name$="[variant_unit_name]"]');

    this.unitValue = this.element.querySelector('[name$="[unit_value]"]');
    this.unitDescription = this.element.querySelector('[name$="[unit_description]"]');
    this.unitValueWithDescription = this.element.querySelector(
      '[name$="[unit_value_with_description]"]',
    );
    this.displayAs = this.element.querySelector('[name$="[display_as]"]');
    this.unitToDisplay = this.element.querySelector('[name$="[unit_to_display]"]');

    // on unit changed; update display_as:placeholder and unit_to_display
    [this.variantUnit, this.variantUnitScale, this.variantUnitName].forEach((element) => {
      element.addEventListener("change", this.#unitChanged.bind(this), { passive: true });
    });
    this.variantUnitName.addEventListener("input", this.#unitChanged.bind(this), { passive: true });

    // on unit_value_with_description changed; update unit_value and unit_description
    // on unit_value and/or unit_description changed; update display_as:placeholder and unit_to_display
    this.unitValueWithDescription.addEventListener("input", this.#unitChanged.bind(this), {
      passive: true,
    });

    // on display_as changed; update unit_to_display
    // TODO: optimise to avoid unnecessary OptionValueNamer calc
    this.displayAs.addEventListener("input", this.#updateUnitDisplay.bind(this), { passive: true });
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
  }

  // private

  // Extract variant_unit and variant_unit_scale from dropdown variant_unit_with_scale,
  // and update hidden product fields
  #unitChanged(event) {
    //Hmm in hindsight the logic in product_controller should be inn this controller already. then we can do everything in one event, and store the generated name in an instance variable.
    this.#extractUnitValues();
    this.#updateUnitDisplay();
  }

  // Extract unit_value and unit_description
  #extractUnitValues() {
    // Extract a number (optional) and text value, separated by a space.
    const match = this.unitValueWithDescription.value.match(/^([\d\.\,]+(?= |$)|)( |)(.*)$/);
    if (match) {
      let unit_value = parseFloat(match[1].replace(",", "."));
      unit_value = isNaN(unit_value) ? null : unit_value;
      unit_value *= this.variantUnitScale.value ? this.variantUnitScale.value : 1; // Normalise to default scale

      this.unitValue.value = unit_value;
      this.unitDescription.value = match[3];
    }
  }

  // Update display_as placeholder and unit_to_display
  #updateUnitDisplay() {
    const unitDisplay = new OptionValueNamer(this.#variant()).name();
    this.displayAs.placeholder = unitDisplay;
    this.unitToDisplay.textContent = this.displayAs.value || unitDisplay;
  }

  // A representation of the variant model to satisfy OptionValueNamer.
  #variant() {
    return {
      unit_value: parseFloat(this.unitValue.value),
      unit_description: this.unitDescription.value,
      product: {
        variant_unit: this.variantUnit.value,
        variant_unit_scale: parseFloat(this.variantUnitScale.value),
        variant_unit_name: this.variantUnitName.value,
      },
    };
  }
}
