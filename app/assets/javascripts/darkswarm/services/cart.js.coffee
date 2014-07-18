Darkswarm.factory 'Cart', (CurrentOrder, Variants, $timeout, $http)->
  # Handles syncing of current cart/order state to server
  new class Cart
    dirty: false
    order: CurrentOrder.order
    line_items: CurrentOrder.order.line_items 
    constructor: ->
      for line_item in @line_items
        line_item.variant.line_item = line_item
        Variants.register line_item.variant

    orderChanged: =>
      @dirty = true
      if @promise
        $timeout.cancel(@promise)
      @promise = $timeout @update, 1000
    update: =>
      console.log "updating the order"

    line_items_present: =>
      @line_items.filter (li)->
        li.quantity > 0

    register_variant: (variant)=>
      exists = @line_items.some (li)-> li.variant == variant
      @create_line_item(variant) unless exists 
        
    create_line_item: (variant)->
      variant.line_item =
        variant: variant
        quantity: 0
      @line_items.push variant.line_item
