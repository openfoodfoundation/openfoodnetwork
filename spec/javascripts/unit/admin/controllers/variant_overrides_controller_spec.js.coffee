describe "VariantOverridesCtrl", ->
  ctrl = null
  scope = {}
  hubs = [{id: 1, name: 'Hub'}]
  producers = [{id: 2, name: 'Producer'}]
  products = [{id: 1, name: 'Product'}]
  hubPermissions = {}
  VariantOverrides = null
  variantOverrides = {}
  DirtyVariantOverrides = null
  dirtyVariantOverrides = {}
  inventoryItems = {}
  StatusMessage = null
  statusMessage = {}

  beforeEach ->
    module 'admin.variantOverrides'
    module ($provide) ->
      $provide.value 'SpreeApiKey', 'API_KEY'
      $provide.value 'variantOverrides', variantOverrides
      $provide.value 'dirtyVariantOverrides', dirtyVariantOverrides
      $provide.value 'inventoryItems', inventoryItems
      $provide.value 'columns', []
      null

    inject ($controller, _VariantOverrides_, _DirtyVariantOverrides_, _StatusMessage_) ->
      VariantOverrides = _VariantOverrides_
      DirtyVariantOverrides = _DirtyVariantOverrides_
      StatusMessage = _StatusMessage_
      ctrl = $controller 'AdminVariantOverridesCtrl', { $scope: scope, hubs: hubs, producers: producers, products: products, hubPermissions: hubPermissions, VariantOverrides: VariantOverrides, DirtyVariantOverrides: DirtyVariantOverrides, StatusMessage: StatusMessage}

  describe "when only one hub is available", ->
    it "initialises the hub list and the selects the only hub in the list", ->
      expect(scope.hubs).toEqual { 1: {id: 1, name: 'Hub'} }
      expect(scope.hub_id).toEqual 1

  describe "when more than one hub is available", ->
    beforeEach ->
      inject ($controller) ->
        two_hubs = [{id: 1, name: 'Hub1'}, {id: 12, name: 'Hub2'}]
        $controller 'AdminVariantOverridesCtrl', { $scope: scope, hubs: two_hubs, producers: [], products: [], hubPermissions: []}

    it "initialises the hub list and the selects the only hub in the list", ->
      expect(scope.hubs).toEqual { 1: {id: 1, name: 'Hub1'}, 12: {id: 12, name: 'Hub2'} }
      expect(scope.hub_id).toBeNull()

  it "initialises select filters", ->
    expect(scope.producerFilter).toEqual 0
    expect(scope.query).toEqual ''

  it "adds products", ->
    spyOn(VariantOverrides, "ensureDataFor")
    expect(scope.products).toEqual []
    scope.addProducts { products: ['a', 'b'] }
    expect(scope.products).toEqual ['a', 'b']
    scope.addProducts { products: ['c', 'd'] }
    expect(scope.products).toEqual ['a', 'b', 'c', 'd']
    expect(VariantOverrides.ensureDataFor).toHaveBeenCalled()

  describe "updating", ->
    describe "error messages", ->
      it "returns an unauthorised message upon 401", ->
        expect(scope.updateError({}, 401)).toEqual "I couldn't get authorisation to save those changes, so they remain unsaved."

      it "returns errors when they are provided", ->
        data = {errors: {base: ["Hub can't be blank", "Variant can't be blank"]}}
        expect(scope.updateError(data, 400)).toEqual "I had some trouble saving: Hub can't be blank, Variant can't be blank"

      it "returns a generic message otherwise", ->
        expect(scope.updateError({}, 500)).toEqual "Oh no! I was unable to save your changes."

  describe "setting stock to defaults", ->
    it "prompts to save changes if there are any pending", ->
      spyOn(StatusMessage, "display")
      DirtyVariantOverrides.add {hub_id: 1, variant_id: 1}
      scope.resetStock()
      expect(StatusMessage.display).toHaveBeenCalledWith  'alert', 'Save changes first.'

    it "updates and refreshes on hand value for variant overrides with a default stock level", inject ($httpBackend) ->
      scope.hub_id = 123
      variant_overrides_mock = "mock object"
      spyOn(StatusMessage, "display")
      spyOn(VariantOverrides, "updateData")
      $httpBackend.expectPOST("/admin/variant_overrides/bulk_reset", hub_id: 123).respond 200, variant_overrides_mock
      scope.resetStock()
      expect(StatusMessage.display).toHaveBeenCalledWith 'progress', 'Changing on hand stock levels...'
      $httpBackend.flush()
      expect(VariantOverrides.updateData).toHaveBeenCalledWith variant_overrides_mock
      expect(StatusMessage.display).toHaveBeenCalledWith 'success', 'Stocks reset to defaults.'

  describe "suggesting count_on_hand when on_demand is changed", ->
    variant = null

    beforeEach ->
      scope.variantOverrides = {123: {}}

    describe "when variant is on demand", ->
      beforeEach ->
        # Ideally, count_on_hand is blank when the variant is on demand. However, this rule is not
        # enforced.
        variant = {id: 2, on_demand: true, on_hand: 20, on_hand: "On demand"}

      it "clears count_on_hand when variant override uses producer stock settings", ->
        scope.variantOverrides[123][2] = {on_demand: null, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBeNull()
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBeNull()

      it "clears count_on_hand when variant override forces on demand", ->
        scope.variantOverrides[123][2] = {on_demand: true, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBeNull()
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBeNull()

      it "clears count_on_hand when variant override forces limited stock", ->
        scope.variantOverrides[123][2] = {on_demand: false, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBeNull()
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBeNull()

    describe "when variant has limited stock", ->
      beforeEach ->
        variant = {id: 2, on_demand: false, count_on_hand: 20, on_hand: 20}

      it "clears count_on_hand when variant override uses producer stock settings", ->
        scope.variantOverrides[123][2] = {on_demand: null, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBeNull()
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBeNull()

      it "clears count_on_hand when variant override forces on demand", ->
        scope.variantOverrides[123][2] = {on_demand: true, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBeNull()
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBeNull()

      it "sets to producer count_on_hand when variant override forces limited stock", ->
        scope.variantOverrides[123][2] = {on_demand: false, count_on_hand: 1}
        scope.updateCountOnHand(variant, 123)

        expect(scope.variantOverrides[123][2].count_on_hand).toBe(20)
        dirtyVariantOverride = DirtyVariantOverrides.dirtyVariantOverrides[123][2]
        expect(dirtyVariantOverride.count_on_hand).toBe(20)

  describe "count on hand placeholder", ->
    beforeEach ->
      scope.variantOverrides = {123: {}}

    describe "when variant is on demand", ->
      variant = null

      beforeEach ->
        # Ideally, count_on_hand is blank when the variant is on demand. However, this rule is not
        # enforced.
        variant = {id: 2, on_demand: true, on_hand: 20, on_hand: t("on_demand")}

      it "is 'On demand' when variant override uses producer stock settings", ->
        scope.variantOverrides[123][2] = {on_demand: null, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe(t("on_demand"))

      it "is 'On demand' when variant override is on demand", ->
        scope.variantOverrides[123][2] = {on_demand: true, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe(t("js.variants.on_demand.yes"))

      it "is blank when variant override is limited stock", ->
        scope.variantOverrides[123][2] = {on_demand: false, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe('')

    describe "when variant is limited stock", ->
      variant = null

      beforeEach ->
        variant = {id: 2, on_demand: false, on_hand: 20, on_hand: 20}

      it "is variant count on hand when variant override uses producer stock settings", ->
        scope.variantOverrides[123][2] = {on_demand: null, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe(20)

      it "is 'On demand' when variant override is on demand", ->
        scope.variantOverrides[123][2] = {on_demand: true, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe(t("js.variants.on_demand.yes"))

      it "is blank when variant override is limited stock", ->
        scope.variantOverrides[123][2] = {on_demand: false, count_on_hand: 1}
        placeholder = scope.countOnHandPlaceholder(variant, 123)
        expect(placeholder).toBe('')
