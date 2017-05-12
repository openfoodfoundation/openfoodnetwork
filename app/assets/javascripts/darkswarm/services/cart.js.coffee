Darkswarm.factory 'Cart', (CurrentOrder, Variants, $timeout, $http, $modal, $rootScope, $resource, localStorageService) ->
  # Handles syncing of current cart/order state to server
  new class Cart
    dirty: false
    update_running: false
    update_enqueued: false
    order: CurrentOrder.order
    line_items: CurrentOrder.order?.line_items || []
    line_items_finalised: CurrentOrder.order?.finalised_line_items || []

    constructor: ->
      for line_item in @line_items
        line_item.variant.line_item = line_item
        Variants.register line_item.variant
      for line_item in @line_items_finalised
        line_item.variant.line_item = line_item
        Variants.extend line_item.variant

    adjust: (line_item) =>
      line_item.total_price = line_item.variant.price_with_fees * line_item.quantity
      if line_item.quantity > 0
        @line_items.push line_item unless line_item in @line_items
      else
        index = @line_items.indexOf(line_item)
        @line_items.splice(index, 1) if index >= 0
      @orderChanged()

    orderChanged: =>
      @unsaved()

      if !@update_running
        @scheduleUpdate()
      else
        @update_enqueued = true

    scheduleUpdate: =>
      if @promise
        $timeout.cancel(@promise)
      @promise = $timeout @update, 1000

    update: =>
      @update_running = true

      $http.post('/orders/populate', @data()).success (data, status)=>
        @saved()
        @update_running = false

        @compareAndNotifyStockLevels data.stock_levels

        @popQueue() if @update_enqueued

      .error (response, status)=>
        @scheduleRetry(status)
        @update_running = false

    compareAndNotifyStockLevels: (stockLevels) =>
      scope = $rootScope.$new(true)
      scope.variants = []

      # TODO: These changes to quantity/max_quantity trigger another cart update, which
      #       is unnecessary.

      for li in @line_items when li.quantity > 0
        if stockLevels[li.variant.id]?
          li.variant.count_on_hand = stockLevels[li.variant.id].on_hand
          if li.quantity > li.variant.count_on_hand
            li.quantity = li.variant.count_on_hand
            scope.variants.push li.variant
          if li.variant.count_on_hand == 0 && li.max_quantity > li.variant.count_on_hand
            li.max_quantity = li.variant.count_on_hand
            scope.variants.push(li.variant) unless li.variant in scope.variants

      if scope.variants.length > 0
        $modal.open(templateUrl: "out_of_stock.html", scope: scope, windowClass: 'out-of-stock-modal')

    popQueue: =>
      @update_enqueued = false
      @scheduleUpdate()

    data: =>
      variants = {}
      for li in @line_items when li.quantity > 0
        variants[li.variant.id] =
          quantity: li.quantity
          max_quantity: li.max_quantity
      {variants: variants}

    scheduleRetry: (status) =>
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
        t 'order_not_saved_yet'

    total_item_count: =>
      @line_items.reduce (sum,li) ->
        sum = sum + li.quantity
      , 0

    empty: =>
      @line_items.length == 0

    total: =>
      @line_items.map (li)->
        li.total_price
      .reduce (t, price)->
        t + price
      , 0

    clear: ->
      @line_items = []
      localStorageService.clearAll() # One day this will have to be moar GRANULAR

    removeFinalisedLineItem: (id) =>
      @line_items_finalised = @line_items_finalised.filter (item) ->
        item.id != id

    reloadFinalisedLineItems: =>
      @line_items_finalised = []
      $resource("/line_items/bought").query (items) =>
        for line_item in items
          line_item.variant.line_item = line_item
          Variants.extend line_item.variant
        @line_items_finalised = items
