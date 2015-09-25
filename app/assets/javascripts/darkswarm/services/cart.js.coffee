Darkswarm.factory 'Cart', (CurrentOrder, Variants, $timeout, $http, storage)->
  # Handles syncing of current cart/order state to server
  new class Cart
    dirty: false
    order: CurrentOrder.order
    line_items: CurrentOrder.order?.line_items || []
    constructor: ->
      for line_item in @line_items
        line_item.variant.line_item = line_item
        Variants.register line_item.variant
        line_item.variant.extended_name = @extendedVariantName(line_item.variant)

    orderChanged: =>
      @unsaved()
      if @promise
        $timeout.cancel(@promise)
      @promise = $timeout @update, 1000

    update: =>
      $http.post('/orders/populate', @data()).success (data, status)=>
        @saved()
      .error (response, status)=>
        @scheduleRetry()

    data: =>
      variants = {}
      for li in @line_items_present()
        variants[li.variant.id] =
          quantity: li.quantity
          max_quantity: li.max_quantity
      {variants: variants}

    scheduleRetry: =>
      console.log "Error updating cart: #{status}. Retrying in 3 seconds..."
      $timeout =>
        console.log "Retrying cart update"
        @orderChanged()
      , 3000

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

    total_item_count: =>
      @line_items_present().reduce (sum,li) ->
        sum = sum + li.quantity
      , 0

    empty: =>
      @line_items_present().length == 0

    total: =>
      @line_items_present().map (li)->
        li.variant.totalPrice()
      .reduce (t, price)->
        t + price
      , 0

    register_variant: (variant)=>
      exists = @line_items.some (li)-> li.variant == variant
      @create_line_item(variant) unless exists

    clear: ->
      @line_items = []
      storage.clearAll() # One day this will have to be moar GRANULAR

    create_line_item: (variant)->
      variant.extended_name = @extendedVariantName(variant)
      variant.line_item =
        variant: variant
        quantity: null
        max_quantity: null
      @line_items.push variant.line_item

    extendedVariantName: (variant) =>
      if variant.product_name == variant.name_to_display
        variant.product_name
      else
        name =  "#{variant.product_name} - #{variant.name_to_display}"
        name += " (#{variant.unit_text})" if variant.unit_text
        name
