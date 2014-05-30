Darkswarm.factory 'CurrentOrder', (currentOrder) ->
  new class CurrentOrder
    constructor: ->
        @[k] = v for k, v of currentOrder
    
    empty: =>
      @line_items.length == 0
