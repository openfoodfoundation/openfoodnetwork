// Requires global variable from page: ofn_available_units_sorted

export default class VariantUnitManager {
  constructor() {
    this.units = this.#loadUnits(ofn_available_units_sorted);
  }

  getUnitName(scale, unitType) {
    if (this.units[unitType][scale]) {
      return this.units[unitType][scale]["name"];
    } else {
      return "";
    }
  }

  // Filter by measurement system
  compatibleUnitScales(scale, unitType) {
    const scaleSystem = this.units[unitType][scale]["system"];

    return Object.entries(this.units[unitType])
      .filter(([scale, scaleInfo]) => {
        return scaleInfo["system"] == scaleSystem;
      })
      .map(([scale, _]) => parseFloat(scale))
      .sort();
  }

  systemOfMeasurement(scale, unitType) {
    if (this.units[unitType][scale]) {
      return this.units[unitType][scale]["system"];
    } else {
      return "custom";
    }
  }

  // private

  #loadUnits(units) {
    // Transform unit scale to a JS Number for compatibility. This would be way simpler in Ruby or Coffeescript!!
    const unitsTransformed = Object.entries(units).map(([measurement, measurementInfo]) => {
      const measurementInfoTransformed = Object.fromEntries(
        Object.entries(measurementInfo).map(([scale, unitInfo]) => [parseFloat(scale), unitInfo]),
      );
      return [measurement, measurementInfoTransformed];
    });
    return Object.fromEntries(unitsTransformed);
  }
}
