angular.module("ofn.admin").factory "DirtyVariantOverrides", ->
  new class DirtyVariantOverrides
    dirtyVariantOverrides: {}

    add: (vo) ->
      @dirtyVariantOverrides[vo.hub_id] ||= {}
      @dirtyVariantOverrides[vo.hub_id][vo.variant_id] = vo

    count: ->
      count = 0
      for hub_id, vos of @dirtyVariantOverrides
        count += Object.keys(vos).length
      count