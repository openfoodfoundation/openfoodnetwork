describe "VariantOverrides service", ->
  VariantOverrides = $httpBackend = null
  variantOverrides = [
    {id: 1, hub_id: 10, variant_id: 100, sku: "V100", price: 1, count_on_hand: 1, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
    {id: 2, hub_id: 10, variant_id: 200, sku: "V200", price: 2, count_on_hand: 2, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
    {id: 3, hub_id: 20, variant_id: 300, sku: "V300", price: 3, count_on_hand: 3, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
  ]

  beforeEach ->
    module "admin.variantOverrides"
    module ($provide) ->
      $provide.value "variantOverrides", variantOverrides
      null

  beforeEach inject (_VariantOverrides_, _$httpBackend_) ->
    VariantOverrides = _VariantOverrides_
    $httpBackend = _$httpBackend_

  it "indexes variant overrides by hub_id -> variant_id", ->
    expect(VariantOverrides.variantOverrides).toEqual
      10:
        100: {id: 1, hub_id: 10, variant_id: 100, sku: "V100", price: 1, count_on_hand: 1, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
        200: {id: 2, hub_id: 10, variant_id: 200, sku: "V200", price: 2, count_on_hand: 2, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      20:
        300: {id: 3, hub_id: 20, variant_id: 300, sku: "V300", price: 3, count_on_hand: 3, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }

  it "ensures blank data available for some products", ->
    hubs = [{id: 10}, {id: 20}, {id: 30}]
    products = [
      {
        id: 1
        variants: [{id: 100}, {id: 200}, {id: 300}, {id: 400}, {id: 500}]
      }
    ]
    VariantOverrides.ensureDataFor hubs, products
    expect(VariantOverrides.variantOverrides[10]).toEqual
      100: { id: 1, hub_id: 10, variant_id: 100, sku: "V100", price: 1,    count_on_hand: 1,    on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      200: { id: 2, hub_id: 10, variant_id: 200, sku: "V200", price: 2,    count_on_hand: 2,    on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      300: {        hub_id: 10, variant_id: 300, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      400: {        hub_id: 10, variant_id: 400, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      500: {        hub_id: 10, variant_id: 500, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
    expect(VariantOverrides.variantOverrides[20]).toEqual
      100: {        hub_id: 20, variant_id: 100, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      200: {        hub_id: 20, variant_id: 200, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      300: { id: 3, hub_id: 20, variant_id: 300, sku: "V300", price: 3,    count_on_hand: 3,    on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      400: {        hub_id: 20, variant_id: 400, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: []}
      500: {        hub_id: 20, variant_id: 500, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
    expect(VariantOverrides.variantOverrides[30]).toEqual
      100: {        hub_id: 30, variant_id: 100, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      200: {        hub_id: 30, variant_id: 200, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      300: {        hub_id: 30, variant_id: 300, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: []}
      400: {        hub_id: 30, variant_id: 400, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }
      500: {        hub_id: 30, variant_id: 500, sku: null,   price: null, count_on_hand: null, on_demand: null, default_stock: null, resettable: false, tag_list : '', tags: [] }

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
