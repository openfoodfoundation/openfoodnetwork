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
      if @totalActive() == 0
        if active then "Hide filters" else "Filter by"
      else
        "#{@totalActive()} filters active"

    clearAll: =>
      for selector in @selectors
        selector.active = false
