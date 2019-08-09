angular.module("admin.products").directive "setOnDemand", ->
  link: (scope, element, attr) ->
    onHand = element.context.querySelector("#variant_on_hand")
    onDemand = element.context.querySelector("#variant_on_demand")

    if onDemand.checked
      onHand.disabled = 'disabled'
      onHand.dataStock = onHand.value
      onHand.value = t('admin.products.variants.infinity')

    onDemand.addEventListener 'change', (event) ->
      if onDemand.checked
        onHand.disabled = 'disabled'
        onHand.dataStock = onHand.value
        onHand.value = t('admin.products.variants.infinity')
      else
        onHand.removeAttribute('disabled')
        onHand.value = onHand.dataStock



