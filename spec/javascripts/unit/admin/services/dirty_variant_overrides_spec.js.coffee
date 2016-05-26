describe "maintaining a list of dirty variant overrides", ->
  DirtyVariantOverrides = null
  variantOverride =
    variant_id: 1
    hub_id: 2
    price: 3
    count_on_hand: 4

  beforeEach ->
    module "admin.variantOverrides"
    module ($provide) ->
      $provide.value "variantOverrides", { 2: { 1: variantOverride } }
      null

  beforeEach inject (_DirtyVariantOverrides_) ->
    DirtyVariantOverrides = _DirtyVariantOverrides_

  describe "adding a new dirty variant override", ->
    it "adds new dirty variant overrides", ->
      DirtyVariantOverrides.add(2,1,5)
      expect(DirtyVariantOverrides.dirtyVariantOverrides).toEqual { 2: { 1: { id: 5, variant_id: 1, hub_id: 2 } } }


  describe "setting the value of an attribute", ->
    beforeEach ->
      spyOn(DirtyVariantOverrides, "add").and.callThrough()

    describe "when a record for the given VO does not exist", ->
      beforeEach ->
        DirtyVariantOverrides.dirtyVariantOverrides = {}

      it "sets the specified attribute on a new dirty VO", ->
        DirtyVariantOverrides.set(2,1,5,'count_on_hand', 10)
        expect(DirtyVariantOverrides.add).toHaveBeenCalledWith(2,1,5)
        expect(DirtyVariantOverrides.dirtyVariantOverrides).toEqual
          2:
            1:
              id: 5
              variant_id: 1
              hub_id: 2
              count_on_hand: 10

    describe "when a record for the given VO exists", ->
      beforeEach ->
        DirtyVariantOverrides.dirtyVariantOverrides = { 2: { 1: { id: 5, variant_id: 1, hub_id: 2, price: 27 } } }

      it "sets the specified attribute on a new dirty VO", ->
        DirtyVariantOverrides.set(2,1,5,'count_on_hand', 10)
        expect(DirtyVariantOverrides.add).toHaveBeenCalledWith(2,1,5)
        expect(DirtyVariantOverrides.dirtyVariantOverrides).toEqual
          2:
            1:
              id: 5
              variant_id: 1
              hub_id: 2
              price: 27
              count_on_hand: 10

  describe "with a number of variant overrides", ->
    beforeEach ->
      DirtyVariantOverrides.dirtyVariantOverrides =
        2:
          1:
            variant_id: 5
            hub_id: 6
            price: 7
            count_on_hand: 8
          3:
            variant_id: 9
            hub_id: 10
            price: 11
            count_on_hand: 12
        4:
          5:
            variant_id: 13
            hub_id: 14
            price: 15
            count_on_hand: 16

    it "counts dirty variant overrides", ->
      expect(DirtyVariantOverrides.count()).toEqual 3

    it "clears dirty variant overrides", ->
      DirtyVariantOverrides.clear()
      expect(DirtyVariantOverrides.dirtyVariantOverrides).toEqual {}

    it "returns a flattened list of overrides", ->
      expect(DirtyVariantOverrides.all()).toEqual [
        {variant_id: 5,  hub_id: 6,  price: 7,  count_on_hand: 8}
        {variant_id: 9,  hub_id: 10, price: 11, count_on_hand: 12}
        {variant_id: 13, hub_id: 14, price: 15, count_on_hand: 16}
      ]
