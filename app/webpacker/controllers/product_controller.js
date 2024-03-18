import { Controller } from "stimulus";

// Dynamically update related Product unit fields (expected to move to Variant due to Product Refactor)
//
export default class ProductController extends Controller {
  connect() {
    // idea: create a helper that includes a nice getter/setter for Rails model attr values, just pass it the attribute name.
    // It could automatically find (and cache a ref to) each dom element and get/set the values.
    this.variantUnit = this.element.querySelector('[name$="[variant_unit]"]');
    this.variantUnitScale = this.element.querySelector('[name$="[variant_unit_scale]"]');
    this.variantUnitWithScale = this.element.querySelector('[name$="[variant_unit_with_scale]"]');

    // on variant_unit_with_scale changed; update variant_unit and variant_unit_scale
    this.variantUnitWithScale.addEventListener("change", this.#updateUnitAndScale.bind(this), {
      passive: true,
    });
  }

  // private

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
}
