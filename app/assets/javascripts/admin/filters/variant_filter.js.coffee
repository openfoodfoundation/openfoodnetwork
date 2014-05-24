angular.module("ofn.admin").filter "variantFilter", ->
    return (lineItems,selectedUnitsProduct,selectedUnitsVariant,sharedResource) ->
      filtered = []
      filtered.push lineItem for lineItem in lineItems when (angular.equals(selectedUnitsProduct,{}) ||
        (lineItem.units_product.id == selectedUnitsProduct.id && (sharedResource || lineItem.units_variant.id == selectedUnitsVariant.id ) ) )
      filtered