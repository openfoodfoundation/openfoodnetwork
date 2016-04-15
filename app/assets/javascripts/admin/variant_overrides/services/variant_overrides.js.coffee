
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
            @inherit(hub.id, variant.id) unless @variantOverrides[hub.id][variant.id]

    inherit: (hub_id, variant_id) ->
      # This method is called from the trackInheritance directive, to reinstate inheritance
      @variantOverrides[hub_id][variant_id] ||= {}
      angular.extend @variantOverrides[hub_id][variant_id], @newFor hub_id, variant_id

    newFor: (hub_id, variant_id) ->
      # These properties need to match those checked in VariantOverrideSet.deletable?
      hub_id: hub_id
      variant_id: variant_id
      sku: null
      price: null
      count_on_hand: null
      on_demand: null
      default_stock: null
      resettable: false
      tag_list: ''
      tags: []

    updateIds: (updatedVos) ->
      for vo in updatedVos
        @variantOverrides[vo.hub_id][vo.variant_id].id = vo.id

    updateData: (updatedVos) ->
      for vo in updatedVos
        @variantOverrides[vo.hub_id][vo.variant_id] = vo
