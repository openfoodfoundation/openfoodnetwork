# Returns a factory with the only function `createSelectors()`.
# That function creates objects managing a list of filter selectors.
angular.module('Darkswarm').factory "FilterSelectorsService", ->
  # This stores all filters so we can access in-use counts etc
  class FilterSelectors
    constructor: ->
      @selectors = []

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

  # Creates instances of `FilterSelectors`
  new class FilterSelectorsService
    createSelectors: ->
      new FilterSelectors
