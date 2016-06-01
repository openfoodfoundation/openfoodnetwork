angular.module("admin.variantOverrides").factory "DirtyVariantOverrides", ($http, VariantOverrides) ->
  new class DirtyVariantOverrides
    dirtyVariantOverrides: {}

    add: (hub_id, variant_id, vo_id) ->
      @dirtyVariantOverrides[hub_id] ||= {}
      @dirtyVariantOverrides[hub_id][variant_id] ||=
        { id: vo_id, variant_id: variant_id, hub_id: hub_id }

    set: (hub_id, variant_id, vo_id, attr, value) ->
      if attr in @requiredAttrs()
        @add(hub_id, variant_id, vo_id)
        @dirtyVariantOverrides[hub_id][variant_id][attr] = value

    inherit: (hub_id, variant_id, vo_id) ->
      @add(hub_id, variant_id, vo_id)
      blankVo = angular.copy(VariantOverrides.inherit(hub_id, variant_id))
      delete blankVo[attr] for attr, value of blankVo when attr not in @requiredAttrs()
      @dirtyVariantOverrides[hub_id][variant_id] = blankVo

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

    save: ->
      $http
        method: "POST"
        url: "/admin/variant_overrides/bulk_update"
        data:
          variant_overrides: @all()

    requiredAttrs: ->
      ['id','hub_id','variant_id','sku','price','count_on_hand','on_demand','default_stock','resettable','tag_list']
