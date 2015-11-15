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
        if active then t('hide_filters') else t('filter_by')
      else if total == 1
        t 'one_filter_applied'
      else
        @totalActive() + t('x_filters_applied')

    clearAll: =>
      for selector in @selectors
        selector.active = false
        selector.emit()
