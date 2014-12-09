angular.module("ofn.admin").factory "DirtyVariantOverrides", ->
  new class DirtyVariantOverrides
    dirtyVariantOverrides: {}

    add: (vo) ->
      @dirtyVariantOverrides[vo.hub_id] ||= {}
      @dirtyVariantOverrides[vo.hub_id][vo.variant_id] = vo
