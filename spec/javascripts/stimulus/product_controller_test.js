/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import product_controller from "../../../app/webpacker/controllers/product_controller";

describe("ProductController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("product", product_controller);
  });

  describe("variant_unit_with_scale", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="product">
          <input id="variant_unit" name="[products][0][variant_unit]" value="weight">
          <input id="variant_unit_scale" name="[products][0][variant_unit_scale]" value="1.0">
          <select id="variant_unit_with_scale" name="[products][0][variant_unit_with_scale]">
            <option selected="selected" value="weight_1">Weight (g)</option>
            <option value="weight_1000">Weight (kg)</option>
            <option value="volume_4.54609">Volume (gal)</option>
            <option value="items">Items</option>
          </select>
        </div>
      `;
    });

    describe("change", () => {
      it("weight_1000", () => {
        variant_unit_with_scale.selectedIndex = 1;
        variant_unit_with_scale.dispatchEvent(new Event("change"));

        expect(variant_unit.value).toBe("weight");
        expect(variant_unit_scale.value).toBe("1000");
      });

      it("volume_4.54609", () => {
        variant_unit_with_scale.selectedIndex = 2;
        variant_unit_with_scale.dispatchEvent(new Event("change"));

        expect(variant_unit.value).toBe("volume");
        expect(variant_unit_scale.value).toBe("4.54609");
      });

      it("items", () => {
        variant_unit_with_scale.selectedIndex = 3;
        variant_unit_with_scale.dispatchEvent(new Event("change"));

        expect(variant_unit.value).toBe("items");
        expect(variant_unit_scale.value).toBe("");
      });
    })
  });
});
