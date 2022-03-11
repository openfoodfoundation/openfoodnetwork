describe "VariantUnitManager", ->
  VariantUnitManager = null

  beforeEach ->
    module "admin.products"
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL,lb,oz"
      null

  beforeEach inject (_VariantUnitManager_) ->
    VariantUnitManager = _VariantUnitManager_

  describe "getUnitName", ->
    it "returns the unit name based on the scale and unit type (weight/volume) provided", ->
      expect(VariantUnitManager.getUnitName(1, "weight")).toEqual "g"
      expect(VariantUnitManager.getUnitName(1000, "weight")).toEqual "kg"
      expect(VariantUnitManager.getUnitName(1000000, "weight")).toEqual "T"
      expect(VariantUnitManager.getUnitName(0.001, "volume")).toEqual "mL"
      expect(VariantUnitManager.getUnitName(1, "volume")).toEqual "L"
      expect(VariantUnitManager.getUnitName(1000, "volume")).toEqual "kL"
      expect(VariantUnitManager.getUnitName(453.6, "weight")).toEqual "lb"
      expect(VariantUnitManager.getUnitName(28.35, "weight")).toEqual "oz"

  describe "unitScales", ->
    it "returns a sorted set of scales for unit type weight", ->
      expect(VariantUnitManager.unitScales('weight')).toEqual [1.0, 28.35, 453.6, 1000.0, 1000000.0]

    it "returns a sorted set of scales for unit type volume", ->
      expect(VariantUnitManager.unitScales('volume')).toEqual [0.001, 1.0, 1000.0]

  describe "compatibleUnitScales", ->
    it "returns a sorted set of compatible scales based on the scale and unit type provided", ->
      expect(VariantUnitManager.compatibleUnitScales(1, "weight")).toEqual [1.0, 1000.0, 1000000.0]
      expect(VariantUnitManager.compatibleUnitScales(453.6, "weight")).toEqual [28.35, 453.6]

  describe "variantUnitOptions", ->
    it "returns an array of options", ->
      expect(VariantUnitManager.variantUnitOptions()).toEqual [
        ["Weight (g)", "weight_1"],
        ["Weight (oz)", "weight_28.35" ],
        ["Weight (lb)", "weight_453.6" ]
        ["Weight (kg)", "weight_1000"],
        ["Weight (T)", "weight_1000000"],
        ["Volume (mL)", "volume_0.001"],
        ["Volume (L)", "volume_1"],
        ["Volume (kL)", "volume_1000"],
        ["Items", "items"]
      ]
