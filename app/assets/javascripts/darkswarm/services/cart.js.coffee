Darkswarm.factory 'Cart', (Order)->
  # Handles syncing of current cart/order state to server
  new class Cart
    order: Order.order

