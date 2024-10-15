/**
 * @jest-environment jsdom
 */

import UnitPrices from "js/services/unit_prices";

describe("UnitPrices service", function () {
  let unitPrices = null;

  beforeAll(() => {
    // Requires global var from page for VariantUnitManager
    global.ofn_available_units_sorted = {
      weight: {
        "1.0": { name: "g", system: "metric" },
        28.35: { name: "oz", system: "imperial" },
        453.6: { name: "lb", system: "imperial" },
        "1000.0": { name: "kg", system: "metric" },
        "1000000.0": { name: "T", system: "metric" },
      },
      volume: {
        0.001: { name: "mL", system: "metric" },
        "1.0": { name: "L", system: "metric" },
        "1000.0": { name: "kL", system: "metric" },
      },
    };
  });

  beforeEach(() => {
    unitPrices = new UnitPrices();
  });

  describe("get correct unit price duo unit/value for weight", function () {
    const unit_type = "weight";

    it("with scale: 1", function () {
      const price = 1;
      const scale = 1;
      const unit_value = 1;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(1000);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with scale and unit_value: 1000", function () {
      const price = 1;
      const scale = 1000;
      const unit_value = 1000;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(1);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with scale: 1000 and unit_value: 2000", function () {
      const price = 1;
      const scale = 1000;
      const unit_value = 2000;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(0.5);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with price: 2", function () {
      const price = 2;
      const scale = 1;
      const unit_value = 1;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(2000);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with price: 2, scale and unit_value: 1000", function () {
      const price = 2;
      const scale = 1000;
      const unit_value = 1000;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(2);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with price: 2, scale: 1000 and unit_value: 2000", function () {
      const price = 2;
      const scale = 1000;
      const unit_value = 2000;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(1);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });

    it("with price: 2, scale: 1000 and unit_value: 500", function () {
      const price = 2;
      const scale = 1000;
      const unit_value = 500;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(4);
      expect(unitPrices.unit(scale, unit_type)).toEqual("kg");
    });
  });

  describe("get correct unit price duo unit/value for volume", function () {
    const unit_type = "volume";

    it("with scale: 1", function () {
      const price = 1;
      const scale = 1;
      const unit_value = 1;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(1);
      expect(unitPrices.unit(scale, unit_type)).toEqual("L");
    });

    it("with price: 2 and unit_value: 0.5", function () {
      const price = 2;
      const scale = 1;
      const unit_value = 0.5;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(4);
      expect(unitPrices.unit(scale, unit_type)).toEqual("L");
    });

    it("with price: 2, scale: 0.001 and unit_value: 0.01", function () {
      const price = 2;
      const scale = 0.001;
      const unit_value = 0.01;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(200);
      expect(unitPrices.unit(scale, unit_type)).toEqual("L");
    });

    it("with price: 20000, scale: 1000 and unit_value: 10000", function () {
      const price = 20000;
      const scale = 1000;
      const unit_value = 10000;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(2);
      expect(unitPrices.unit(scale, unit_type)).toEqual("L");
    });

    it("with price: 2, scale: 1000 and unit_value: 10000 and variant_unit_name: box", function () {
      const price = 20000;
      const scale = 1000;
      const unit_value = 10000;
      const variant_unit_name = "Box";
      expect(unitPrices.price(price, scale, unit_type, unit_value, variant_unit_name)).toEqual(2);
      expect(unitPrices.unit(scale, unit_type, variant_unit_name)).toEqual("L");
    });
  });

  describe("get correct unit price duo unit/value for items", function () {
    const unit_type = "items";
    const scale = null;

    it("with price: 1 and unit_value: 1", function () {
      const price = 1;
      const unit_value = 1;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(1);
      expect(unitPrices.unit(scale, unit_type)).toEqual("item");
    });

    it("with price: 1 and unit_value: 10", function () {
      const price = 1;
      const unit_value = 10;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(0.1);
      expect(unitPrices.unit(scale, unit_type)).toEqual("item");
    });

    it("with price: 10 and unit_value: 1", function () {
      const price = 10;
      const unit_value = 1;
      expect(unitPrices.price(price, scale, unit_type, unit_value)).toEqual(10);
      expect(unitPrices.unit(scale, unit_type)).toEqual("item");
    });

    it("with price: 10 and unit_value: 1 and variant_unit_name: box", function () {
      const price = 10;
      const unit_value = 1;
      const variant_unit_name = "Box";
      expect(unitPrices.price(price, scale, unit_type, unit_value, variant_unit_name)).toEqual(10);
      expect(unitPrices.unit(scale, unit_type, variant_unit_name)).toEqual("Box");
    });
  });
});
