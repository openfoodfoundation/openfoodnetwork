angular.module("admin.variantOverrides").filter "importDate", ($filter, variantOverrides) ->
  return (products, hub_id, date) ->
    return [] if !hub_id
    return $filter('filter')(products, (product) ->
      return true if date == 0 or date == undefined or date == '0' or date == ''

      for variant in product.variants
        for vo in variantOverrides
          if vo.variant_id == variant.id and vo.import_date == date
            return true
      false
    , true)