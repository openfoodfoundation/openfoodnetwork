Darkswarm.factory 'Cart', (CurrentOrder)->
  # Handles syncing of current cart/order state to server
  new class Cart
    order: CurrentOrder.order

