Darkswarm.factory 'CurrentOrder', (currentOrder) ->
  new class CurrentOrder
    constructor: ->
        @[k] = v for k, v of currentOrder
        @cart_count ?= 0

    empty: =>
      @line_items.length == 0
