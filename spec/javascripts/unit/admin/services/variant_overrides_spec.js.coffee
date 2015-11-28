describe "VariantOverrides service", ->
  VariantOverrides = $httpBackend = null
  variantOverrides = [
    {id: 1, hub_id: 10, variant_id: 100, price: 1, count_on_hand: 1, default_stock: '', resettable: false}
    {id: 2, hub_id: 10, variant_id: 200, price: 2, count_on_hand: 2, default_stock: '', resettable: false}
    {id: 3, hub_id: 20, variant_id: 300, price: 3, count_on_hand: 3, default_stock: '', resettable: false}
  ]

  beforeEach ->
    module "ofn.admin"
    module ($provide) ->
      $provide.value "variantOverrides", variantOverrides
      null

  beforeEach inject (_VariantOverrides_, _$httpBackend_) ->
    VariantOverrides = _VariantOverrides_
    $httpBackend = _$httpBackend_

  it "indexes variant overrides by hub_id -> variant_id", ->
    expect(VariantOverrides.variantOverrides).toEqual
      10:
        100: {id: 1, hub_id: 10, variant_id: 100, price: 1, count_on_hand: 1, default_stock: '', resettable: false}
        200: {id: 2, hub_id: 10, variant_id: 200, price: 2, count_on_hand: 2, default_stock: '', resettable: false}
      20:
        300: {id: 3, hub_id: 20, variant_id: 300, price: 3, count_on_hand: 3, default_stock: '', resettable: false}

  it "ensures blank data available for some products", ->
    hubs = [{id: 10}, {id: 20}, {id: 30}]
    products = [
      {
        id: 1
        variants: [{id: 100}, {id: 200}, {id: 300}, {id: 400}, {id: 500}]
      }
    ]
    VariantOverrides.ensureDataFor hubs, products
    expect(VariantOverrides.variantOverrides).toEqual
      10:
        100: {id: 1, hub_id: 10, variant_id: 100, price: 1, count_on_hand: 1, default_stock: '', resettable: false}
        200: {id: 2, hub_id: 10, variant_id: 200, price: 2, count_on_hand: 2, default_stock: '', resettable: false}
        300: {       hub_id: 10, variant_id: 300, price: '', count_on_hand: '', default_stock: '', resettable: false}
        400: {       hub_id: 10, variant_id: 400, price: '', count_on_hand: '', default_stock: '', resettable: false}
        500: {       hub_id: 10, variant_id: 500, price: '', count_on_hand: '', default_stock: '', resettable: false}
      20:
        100: {       hub_id: 20, variant_id: 100, price: '', count_on_hand: '', default_stock: '', resettable: false}
        200: {       hub_id: 20, variant_id: 200, price: '', count_on_hand: '', default_stock: '', resettable: false}
        300: {id: 3, hub_id: 20, variant_id: 300, price: 3, count_on_hand: 3, default_stock: '', resettable: false}
        400: {       hub_id: 20, variant_id: 400, price: '', count_on_hand: '', default_stock: '', resettable: false}
        500: {       hub_id: 20, variant_id: 500, price: '', count_on_hand: '', default_stock: '', resettable: false}
      30:
        100: {       hub_id: 30, variant_id: 100, price: '', count_on_hand: '', default_stock: '', resettable: false}
        200: {       hub_id: 30, variant_id: 200, price: '', count_on_hand: '', default_stock: '', resettable: false}
        300: {       hub_id: 30, variant_id: 300, price: '', count_on_hand: '', default_stock: '', resettable: false}
        400: {       hub_id: 30, variant_id: 400, price: '', count_on_hand: '', default_stock: '', resettable: false}
        500: {       hub_id: 30, variant_id: 500, price: '', count_on_hand: '', default_stock: '', resettable: false}

  it "updates the IDs of variant overrides", ->
    VariantOverrides.variantOverrides[2] = {}
    VariantOverrides.variantOverrides[2][3] = {hub_id: 2, variant_id: 3, price: "4.0", count_on_hand: 5, default_stock: '', resettable: false}
    VariantOverrides.variantOverrides[2][8] = {hub_id: 2, variant_id: 8, price: "9.0", count_on_hand: 10, default_stock: '', resettable: false}

    updatedVos = [
      {id: 1, hub_id: 2, variant_id: 3, price: "4.0", count_on_hand: 5, default_stock: '', resettable: false}
      {id: 6, hub_id: 2, variant_id: 8, price: "9.0", count_on_hand: 10, default_stock: '', resettable: false}
    ]

    VariantOverrides.updateIds updatedVos

    expect(VariantOverrides.variantOverrides[2][3].id).toEqual 1
    expect(VariantOverrides.variantOverrides[2][8].id).toEqual 6

  it "sends an HTTP request to reset stock", ->
    $httpBackend.expectPOST("/admin/variant_overrides/bulk_reset", variant_overrides: variantOverrides).respond 200
    VariantOverrides.resetStock variantOverrides
    $httpBackend.flush()

  it "updates the variant overrides on the page with new data", ->
    VariantOverrides.variantOverrides[1] =
      3: {id: 1, hub_id: 1, variant_id: 3, price: "4.0", count_on_hand: 5, default_stock: 3, resettable: true}
      8: {id: 2, hub_id: 1, variant_id: 8, price: "9.0", count_on_hand: 10, default_stock: '', resettable: false}
      # Updated count on hand to 3
    updatedVos = [
      {id: 1, hub_id: 1, variant_id: 3, price: "4.0", count_on_hand: 3, default_stock: 3, resettable: true}
    ]

    VariantOverrides.updateData(updatedVos)
    expect(VariantOverrides.variantOverrides[1]).toEqual
      3: {id: 1, hub_id: 1, variant_id: 3, price: "4.0", count_on_hand: 3, default_stock: 3, resettable: true}
      8: {id: 2, hub_id: 1, variant_id: 8, price: "9.0", count_on_hand: 10, default_stock: '', resettable: false}
