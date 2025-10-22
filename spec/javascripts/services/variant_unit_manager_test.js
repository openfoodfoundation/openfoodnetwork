/**
 * @jest-environment jsdom
 */

import VariantUnitManager from "../../../app/webpacker/js/services/variant_unit_manager";

describe("VariantUnitManager", function () {
  let subject;

  describe("with default units", function () {
    beforeAll(() => {
      // Requires global var from page
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
      subject = new VariantUnitManager();
    });

    describe("getUnitName", function () {
      it("returns the unit name based on the scale and unit type (weight/volume) provided", function () {
        expect(subject.getUnitName(1, "weight")).toEqual("g");
        expect(subject.getUnitName(1000, "weight")).toEqual("kg");
        expect(subject.getUnitName(1000000, "weight")).toEqual("T");
        expect(subject.getUnitName(0.001, "volume")).toEqual("mL");
        expect(subject.getUnitName(1, "volume")).toEqual("L");
        expect(subject.getUnitName(1000, "volume")).toEqual("kL");
        expect(subject.getUnitName(453.6, "weight")).toEqual("lb");
        expect(subject.getUnitName(28.35, "weight")).toEqual("oz");
      });
    });

    describe("compatibleUnitScales", function () {
      it("returns a sorted set of compatible scales based on the scale and unit type provided", function () {
        expect(subject.compatibleUnitScales(1, "weight")).toEqual([1.0, 1000.0, 1000000.0]);
        expect(subject.compatibleUnitScales(453.6, "weight")).toEqual([28.35, 453.6]);
        expect(subject.compatibleUnitScales(0.001, "volume")).toEqual([0.001, 1.0, 1000.0]);
      });
    });
  });

  describe("should only load available units", function () {
    beforeAll(() => {
      // Available units: "g,T,mL,L,kL,lb"
      global.ofn_available_units_sorted = {
        weight: {
          "1.0": { name: "g", system: "metric" },
          453.6: { name: "lb", system: "imperial" },
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
      subject = new VariantUnitManager();
    });

    describe("compatibleUnitScales", function () {
      it("returns a sorted set of compatible scales based on the scale and unit type provided", function () {
        expect(subject.compatibleUnitScales(1, "weight")).toEqual([1.0, 1000000.0]);
        expect(subject.compatibleUnitScales(453.6, "weight")).toEqual([453.6]);
      });
    });
  });
});
