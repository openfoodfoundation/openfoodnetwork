angular.module("admin.variantOverrides").factory "VariantOverrides", (variantOverrides) ->
  new class VariantOverrides
    variantOverrides: {}

    constructor: ->
      for vo in variantOverrides
        @variantOverrides[vo.hub_id] ||= {}
        @variantOverrides[vo.hub_id][vo.variant_id] = vo

    ensureDataFor: (hubs, products) ->
      for hub_id, hub of hubs
        @variantOverrides[hub.id] ||= {}
        for product in products
          for variant in product.variants
            @variantOverrides[hub.id][variant.id] ||=
              variant_id: variant.id
              hub_id: hub.id
              sku: null
              price: null
              count_on_hand: null
              on_demand: null

    updateIds: (updatedVos) ->
      for vo in updatedVos
        @variantOverrides[vo.hub_id][vo.variant_id].id = vo.id
