import { Controller } from "stimulus";
import OptionValueNamer from "js/services/option_value_namer";
import UnitPrices from "js/services/unit_prices";

// Dynamically update related variant fields
//
// TODO refactor so we can extract what's common with Bulk product page
export default class EditVariantController extends Controller {
  static targets = ["onHand"];

  connect() {
    this.unitPrices = new UnitPrices();
    // idea: create a helper that includes a nice getter/setter for Rails model attr values, just pass it the attribute name.
    // It could automatically find (and cache a ref to) each dom element and get/set the values.
    this.variantUnit = this.element.querySelector('[id="variant_variant_unit"]');
    this.variantUnitScale = this.element.querySelector('[id="variant_variant_unit_scale"]');
    this.variantUnitName = this.element.querySelector('[id="variant_variant_unit_name"]');
    this.variantUnitWithScale = this.element.querySelector(
      '[id="variant_variant_unit_with_scale"]',
    );
    this.variantPrice = this.element.querySelector('[id="variant_price"]');

    // on variant_unit_with_scale changed; update variant_unit and variant_unit_scale
    this.variantUnitWithScale.addEventListener("change", this.#updateUnitAndScale.bind(this), {
      passive: true,
    });

    this.unitValue = this.element.querySelector('[id="variant_unit_value"]');
    this.unitDescription = this.element.querySelector('[id="variant_unit_description"]');
    this.unitValueWithDescription = this.element.querySelector(
      '[id="variant_unit_value_with_description"]',
    );
    this.displayAs = this.element.querySelector('[id="variant_display_as"]');
    this.unitToDisplay = this.element.querySelector('[id="variant_unit_to_display"]');

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

    // update Unit price when variant_unit_with_scale or price changes
    [this.variantUnitWithScale, this.variantPrice].forEach((element) => {
      element.addEventListener("change", this.#processUnitPrice.bind(this), { passive: true });
    });
    this.unitValueWithDescription.addEventListener("input", this.#processUnitPrice.bind(this), {
      passive: true,
    });

    // on variantUnit change we need to check if weight needs to be toggled
    this.variantUnit.addEventListener("change", this.#toggleWeight.bind(this), { passive: true });

    // make sure the unit is correct when page is reload after an error
    this.#updateUnitDisplay();
    // update unit price on page load
    this.#processUnitPrice();

    if (this.variantUnit.value === "weight") {
      return this.#hideWeight();
    }
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    // TODO remove all added event
    this.variantUnit.removeEventListener("change", this.#toggleWeight.bind(this), {
      passive: true,
    });
  }

  toggleOnHand(event) {
    if (event.target.checked === true) {
      this.onHandTarget.dataStock = this.onHandTarget.value;
      this.onHandTarget.value = I18n.t("admin.products.variants.infinity");
      this.onHandTarget.disabled = "disabled";
    } else {
      this.onHandTarget.removeAttribute("disabled");
      this.onHandTarget.value = this.onHandTarget.dataStock;
    }
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
      variant_unit: this.variantUnit.value,
      variant_unit_scale: parseFloat(this.variantUnitScale.value),
      variant_unit_name: this.variantUnitName.value,
    };
  }

  // Extract variant_unit and variant_unit_scale from dropdown variant_unit_with_scale,
  // and update hidden product fields
  #updateUnitAndScale(event) {
    const variant_unit_with_scale = this.variantUnitWithScale.value;
    const match = variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/); // eg "weight_1000"

    if (match) {
      this.variantUnit.value = match[1];
      this.variantUnitScale.value = parseFloat(match[2]);
    } else {
      // "items"
      this.variantUnit.value = variant_unit_with_scale;
      this.variantUnitScale.value = "";
    }
    this.variantUnit.dispatchEvent(new Event("change"));
    this.variantUnitScale.dispatchEvent(new Event("change"));
  }

  #processUnitPrice() {
    const unit_type = this.variantUnit.value;

    // TODO double check this
    let unit_value = 1;
    if (unit_type != "items") {
      unit_value = this.unitValue.value;
    }

    const unit_price = this.unitPrices.displayableUnitPrice(
      this.variantPrice.value,
      parseFloat(this.variantUnitScale.value),
      unit_type,
      unit_value,
      this.variantUnitName.value,
    );

    this.element.querySelector('[id="variant_unit_price"]').value = unit_price;
  }

  #hideWeight() {
    this.weight = this.element.querySelector('[id="variant_weight"]');
    this.weight.parentElement.style.display = "none";
  }

  #toggleWeight() {
    if (this.variantUnit.value === "weight") {
      return this.#hideWeight();
    }

    // Show weight
    this.weight = this.element.querySelector('[id="variant_weight"]');
    this.weight.parentElement.style.display = "block";
    // Clearing weight value to remove calculated weight for a variant with unit set to "weight"
    // See Spree::Variant hook update_weight_from_unit_value
    this.weight.value = "";
  }
}
