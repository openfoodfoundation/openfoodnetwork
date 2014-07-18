Darkswarm.factory 'Cart', (CurrentOrder)->
  # Handles syncing of current cart/order state to server
  new class Cart
    order: CurrentOrder.order
    line_items: CurrentOrder.order.line_items 
    constructor: ->
      console.log @order.line_items


