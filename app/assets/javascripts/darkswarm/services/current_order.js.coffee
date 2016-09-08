Darkswarm.factory 'CurrentOrder', (currentOrder) ->
  # Populate Currentorder.order from json in page. This is probably redundant now.
  new class CurrentOrder
    # order: currentOrder

    getOrder: ->
      if currentOrder && currentOrder.bill_address
        currentOrder.bill_address.state_id = currentOrder.bill_address.state_id + ''
        currentOrder.bill_address.country_id = currentOrder.bill_address.country_id + ''

      if currentOrder && currentOrder.ship_address
        currentOrder.ship_address.state_id = currentOrder.ship_address.state_id + ''
        currentOrder.ship_address.country_id = currentOrder.ship_address.country_id + ''

      currentOrder

