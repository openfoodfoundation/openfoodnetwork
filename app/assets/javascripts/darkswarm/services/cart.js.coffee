Darkswarm.factory 'Cart', (CurrentOrder, Variants)->
  # Handles syncing of current cart/order state to server
  new class Cart
    order: CurrentOrder.order
    line_items: CurrentOrder.order.line_items 
    constructor: ->
      for line_item in @line_items
        line_item.variant.line_item = line_item
        Variants.register line_item.variant

    register_variant: (variant)=>
      @create_line_item(variant) unless @line_items.some (li)-> 
        li.variant == variant

    create_line_item: (variant)->
      li =
        variant: variant
        quantity: 0
      variant.line_item = li
      @line_items.push li

