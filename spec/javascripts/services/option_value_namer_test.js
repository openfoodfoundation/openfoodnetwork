/**
 * @jest-environment jsdom
 */

import OptionValueNamer from "js/services/option_value_namer";

describe("OptionValueNamer", () => {
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
  });

  describe("generating option value name", function () {
    var v, namer;
    beforeEach(function () {
      v = {};
      var ofn_available_units_sorted = ofn_available_units_sorted;
      namer = new OptionValueNamer(v);
    });

    it("when unit is blank (empty items name)", function () {
      jest.spyOn(namer, "value_scaled").mockImplementation(() => true);
      jest.spyOn(namer, "option_value_value_unit").mockImplementation(() => ["value", ""]);
      expect(namer.name()).toBe("value");
    });

    it("when description is blank", function () {
      v.unit_description = null;
      jest.spyOn(namer, "value_scaled").mockImplementation(() => true);
      jest.spyOn(namer, "option_value_value_unit").mockImplementation(() => ["value", "unit"]);
      expect(namer.name()).toBe("valueunit");
    });

    it("when description is present", function () {
      v.unit_description = "desc";
      jest.spyOn(namer, "option_value_value_unit").mockImplementation(() => ["value", "unit"]);
      jest.spyOn(namer, "value_scaled").mockImplementation(() => true);
      expect(namer.name()).toBe("valueunit desc");
    });

    it("when value is blank and description is present", function () {
      v.unit_description = "desc";
      jest.spyOn(namer, "option_value_value_unit").mockImplementation(() => [null, null]);
      jest.spyOn(namer, "value_scaled").mockImplementation(() => true);
      expect(namer.name()).toBe("desc");
    });

    it("spaces value and unit when value is unscaled", function () {
      v.unit_description = null;
      jest.spyOn(namer, "option_value_value_unit").mockImplementation(() => ["value", "unit"]);
      jest.spyOn(namer, "value_scaled").mockImplementation(() => false);
      expect(namer.name()).toBe("value unit");
    });

    describe("determining if a variant's value is scaled", function () {
      beforeEach(function () {
        v = {};
        namer = new OptionValueNamer(v);
      });
      it("returns true when the product has a scale", function () {
        v.variant_unit_scale = 1000;
        expect(namer.value_scaled()).toBe(true);
      });
      it("returns false otherwise", function () {
        expect(namer.value_scaled()).toBe(false);
      });
    });

    describe("generating option value's value and unit", function () {
      var v, namer;

      // Mock I18n. TODO: moved to a shared helper
      beforeAll(() => {
        const mockedT = jest.fn();
        mockedT.mockImplementation((string, opts) => string + ", " + JSON.stringify(opts));

        global.I18n = { t: mockedT };
      });
      // (jest still doesn't have aroundEach https://github.com/jestjs/jest/issues/4543 )
      afterAll(() => {
        delete global.I18n;
      });

      beforeEach(function () {
        v = {};
        namer = new OptionValueNamer(v);
      });
      it("generates simple values", function () {
        v.variant_unit = "weight";
        v.variant_unit_scale = 1.0;
        v.unit_value = 100;
        expect(namer.option_value_value_unit()).toEqual([100, "g"]);
      });
      it("generates values when unit value is non-integer", function () {
        v.variant_unit = "weight";
        v.variant_unit_scale = 1.0;
        v.unit_value = 123.45;
        expect(namer.option_value_value_unit()).toEqual([123.45, "g"]);
      });
      it("returns a value of 1 when unit value equals the scale", function () {
        v.variant_unit = "weight";
        v.variant_unit_scale = 1000.0;
        v.unit_value = 1000.0;
        expect(namer.option_value_value_unit()).toEqual([1, "kg"]);
      });
      it("generates values for all weight scales", function () {
        [
          [1.0, "g"],
          [1000.0, "kg"],
          [1000000.0, "T"],
        ].forEach(([scale, unit]) => {
          v.variant_unit = "weight";
          v.variant_unit_scale = scale;
          v.unit_value = 100 * scale;
          expect(namer.option_value_value_unit()).toEqual([100, unit]);
        });
      });
      it("generates values for all volume scales", function () {
        [
          [0.001, "mL"],
          [1.0, "L"],
          [1000.0, "kL"],
        ].forEach(([scale, unit]) => {
          v.variant_unit = "volume";
          v.variant_unit_scale = scale;
          v.unit_value = 100 * scale;
          expect(namer.option_value_value_unit()).toEqual([100, unit]);
        });
      });
      it("generates right values for volume with rounded values", function () {
        var unit;
        unit = "L";
        v.variant_unit = "volume";
        v.variant_unit_scale = 1.0;
        v.unit_value = 0.7;
        expect(namer.option_value_value_unit()).toEqual([700, "mL"]);
      });
      it("chooses the correct scale when value is very small", function () {
        v.variant_unit = "volume";
        v.variant_unit_scale = 0.001;
        v.unit_value = 0.0001;
        expect(namer.option_value_value_unit()).toEqual([0.1, "mL"]);
      });
      it("generates values for item units", function () {
        //TODO
        // %w(packet box).each do |unit|
        //   p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: unit)
        //   v.stub(:product) { p }
        //   v.stub(:unit_value) { 100 }
        //   subject.option_value_value_unit.should == [100, unit.pluralize]
      });
      it("generates singular values for item units when value is 1", function () {
        v.variant_unit = "items";
        v.variant_unit_scale = null;
        v.variant_unit_name = "packet";
        v.unit_value = 1;
        expect(namer.option_value_value_unit()).toEqual([1, "packet"]);
      });
      it("returns [null, null] when unit value is not set", function () {
        v.variant_unit = "items";
        v.variant_unit_scale = null;
        v.variant_unit_name = "foo";
        v.unit_value = null;
        expect(namer.option_value_value_unit()).toEqual([null, null]);
      });
    });
  });
});
