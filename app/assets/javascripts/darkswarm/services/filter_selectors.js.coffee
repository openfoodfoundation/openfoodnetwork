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

    clearAll: =>
      for selector in @selectors
        selector.active = false
