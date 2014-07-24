Darkswarm.factory 'Cart', (CurrentOrder, Variants, $timeout, $http)->
  # Handles syncing of current cart/order state to server
  new class Cart
    dirty: false
    order: CurrentOrder.order
    line_items: CurrentOrder.order?.line_items || [] 
    constructor: ->
      for line_item in @line_items
        line_item.variant.line_item = line_item
        Variants.register line_item.variant

    orderChanged: =>
      @unsaved()
      if @promise
        $timeout.cancel(@promise)
      @promise = $timeout @update, 1000

    update: =>
      $http.post('/orders/populate', @data()).success (data, status)=>
        @saved()
      .error (response, status)=>
        alert "There was an error on the server! Please refresh the page"

    data: =>
      variants = {} 
      for li in @line_items_present()
        variants[li.variant.id] = li.quantity
      {variants: variants}
  

    saved: =>
      @dirty = false
      $(window).unbind "beforeunload"

    unsaved: =>
      @dirty = true
      $(window).bind "beforeunload", ->
        "Your order hasn't been saved yet. Give us a few seconds to finish!"

    line_items_present: =>
      @line_items.filter (li)->
        li.quantity > 0

    total: =>
      @line_items_present().map (li)->
        li.variant.getPrice()
      .reduce (t, price)->
        t + price
      , 0

    register_variant: (variant)=>
      exists = @line_items.some (li)-> li.variant == variant
      @create_line_item(variant) unless exists 
        
    create_line_item: (variant)->
      variant.line_item =
        variant: variant
        quantity: 0
      @line_items.push variant.line_item
