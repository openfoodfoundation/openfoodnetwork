# Lets the add to cart widgets of a product page shown over the product list (see
# product_page_overlay_controller.js) work with the shop's cart.
#
# The shop's cart saves all its line items at once, so it has to know about every change.
# The widgets ask it for their quantity when they appear and leave their changes to it.
angular.module('Darkswarm').directive "productPageOverlayCart", (Cart, Variants) ->
  restrict: "A"
  link: (scope, element) ->
    lineItemOf = (event) ->
      Variants.variants[event.detail.variantId]?.line_item

    element[0].addEventListener "add-to-cart:connect", (event) ->
      line_item = lineItemOf(event)
      return unless line_item?

      event.detail.quantity = line_item.quantity || 0
      event.detail.maxQuantity = line_item.max_quantity || 0

    # Group buy widgets change the max quantity too. Others leave it alone, like the list does.
    element[0].addEventListener "add-to-cart:change", (event) ->
      line_item = lineItemOf(event)
      return unless line_item?

      event.preventDefault()
      scope.$apply ->
        line_item.quantity = event.detail.quantity
        line_item.max_quantity = event.detail.maxQuantity if event.detail.maxQuantity?
        Cart.adjust(line_item)
