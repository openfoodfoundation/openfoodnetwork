Darkswarm.factory 'CurrentOrder', (currentOrder) ->
  new class CurrentOrder
    order: currentOrder
    empty: =>
      @order.line_items.length == 0
