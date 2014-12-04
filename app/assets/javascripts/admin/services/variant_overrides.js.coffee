angular.module("ofn.admin").factory "VariantOverrides", (variantOverrides, Indexer) ->
  new class VariantOverrides
    variantOverrides: {}

    constructor: ->
      for vo in variantOverrides
        @variantOverrides[vo.hub_id] ||= {}
        @variantOverrides[vo.hub_id][vo.variant_id] = vo
