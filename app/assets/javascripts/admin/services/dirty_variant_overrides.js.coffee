angular.module("ofn.admin").factory "DirtyVariantOverrides", ($http) ->
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

    clear: ->
      @dirtyVariantOverrides = {}

    all: ->
      all_vos = []
      for hub_id, vos of @dirtyVariantOverrides
        all_vos.push vo for variant_id, vo of vos
      all_vos

    save: (callbacks={}) ->
      $http
        method: "POST"
        url: "/admin/products/override_variants"
        data:
          variant_overrides: @all()
      .success (data) ->
        (callbacks.success || Angular.noop) data
      .error (data, status) ->
        (callbacks.error || Angular.noop) data, status
