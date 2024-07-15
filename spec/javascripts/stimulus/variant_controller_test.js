/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import variant_controller from "controllers/variant_controller";

describe("VariantController", () => {
  beforeAll(() => {
    // Requires global var from page
    global.ofn_available_units_sorted = {
      weight: {
        "1.0": { name: "g", system: "metric" },
        "1000.0": { name: "kg", system: "metric" },
        "1000000.0": { name: "T", system: "metric" },
      },
      volume: {
        0.001: { name: "mL", system: "metric" },
        "1.0": { name: "L", system: "metric" },
        4.54609: { name: "gal", system: "imperial" },
        "1000.0": { name: "kL", system: "metric" },
      },
    };

    const mockedT = jest.fn();
    mockedT.mockImplementation((string, opts) => string + ", " + JSON.stringify(opts));

    global.I18n = { t: mockedT };

    const application = Application.start();
    application.register("variant", variant_controller);
  });

  afterAll(() => {
    delete global.I18n;
  });

  describe("variant_unit_with_scale", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="variant">
          <input id="variant_unit" name="[products][0][variants_attributes][0][variant_unit]" value="weight">
          <input id="variant_unit_scale" name="[products][0][variants_attributes][0][variant_unit_scale]" value="1.0">
          <select id="variant_unit_with_scale" name="[products][0][variants_attributes][0][variant_unit_with_scale]">
            <option selected="selected" value="weight_1">Weight (g)</option>
            <option value="weight_1000">Weight (kg)</option>
            <option value="volume_4.54609">Volume (gal)</option>
            <option value="items">Items</option>
          </select>
          <input id="variant_unit_name" name="[products][0][variants_attributes][0][variant_unit_name]" type="text" >
          <button id="unit_to_display" name="[products][0][variants_attributes][][0][unit_to_display]" type="submit" >2kg</button>
          <input id="unit_value" name="[products][0][variants_attributes][0][unit_value]" value="2000.0"  >
          <input id="unit_description" name="[products][0][variants_attributes][0][unit_description]" >
          <input id="unit_value_with_description" name="[products][0][variants_attributes][0][unit_value_with_description]" value="2" type="text" >
          <input id="display_as" name="[products][0][variants_attributes][0][display_as]" placeholder="2kg" type="text" >
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
    });
  });
});
