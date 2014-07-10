Darkswarm.factory "FilterSelectorsService", ->
  # This stores all filters so we can access in-use counts etc
  # Accessed via activeSelector Directive
  new class FilterSelectorsService
    selectors: []
    new: (obj = {})->
      obj.active = false
      @selectors.push obj
      obj

    totalActive: =>
      @selectors.filter (selector)->
        selector.active
      .length

    filterText: (active)=>
      total = @totalActive()
      if total == 0
        if active then "Hide filters" else "Filter by"
      else if total == 1
        "1 filter applied"
      else
        "#{@totalActive()} filters applied"

    clearAll: =>
      for selector in @selectors
        selector.active = false
        selector.emit()
