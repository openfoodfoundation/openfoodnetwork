// todo load availableUnits. Hmm why not just load from the dropdown?
export default class VariantUnitManager {
  static availableUnits = 'g,kg,T,mL,L,gal,kL';
  // todo: load units from Ruby also?
  static units = {
    weight: {
      0.001: {
        name: 'mg',
        system: 'metric'
      },
      1.0: {
        name: 'g',
        system: 'metric'
      },
      1000.0: {
        name: 'kg',
        system: 'metric'
      },
      1000000.0: {
        name: 'T',
        system: 'metric'
      },
      453.6: {
        name: 'lb',
        system: 'imperial'
      },
      28.35: {
        name: 'oz',
        system: 'imperial'
      }
    },
    volume: {
      0.001: {
        name: 'mL',
        system: 'metric'
      },
      0.01: {
        name: 'cL',
        system: 'metric'
      },
      0.1: {
        name: 'dL',
        system: 'metric'
      },
      1.0: {
        name: 'L',
        system: 'metric'
      },
      1000.0: {
        name: 'kL',
        system: 'metric'
      },
      4.54609: {
        name: 'gal',
        system: 'metric'
      }
    },
    items: {
      1: {
        name: 'items'
      }
    }
  };

  static getUnitName = (scale, unitType) => {
    if (this.units[unitType][scale]) {
      return this.units[unitType][scale]['name'];
    } else {
      return '';
    }
  };

 // filter by system and format
  static compatibleUnitScales = (scale, unitType) => {
    const scaleSystem = this.units[unitType][scale]['system'];
    if (this.availableUnits) {
      const available = this.availableUnits.split(",");
      return Object.entries(this.units[unitType])
        .filter(([scale, scaleInfo]) => {
          return scaleInfo['system'] == scaleSystem && available.includes(scaleInfo['name']);
        })
        .map(([scale, _]) => parseFloat(scale))
        .sort((a, b) => a - b);
    } else {
      return Object.entries(this.units[unitType])
        .filter(([scale, scaleInfo]) => {
          return scaleInfo['system'] == scaleSystem;
        })
        .map(([scale, _]) => parseFloat(scale))
        .sort((a, b) => a - b);
    }
  };
}
