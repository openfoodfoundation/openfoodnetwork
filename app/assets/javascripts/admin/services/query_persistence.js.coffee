angular.module("admin.indexUtils").factory 'QueryPersistence', (localStorageService)->
  new class QueryPersistence
    storageKey: ''
    storableFilters: []

    constructor: ->
      localStorageService.setStorageType("sessionStorage")

    getStoredFilters: ->
      localStorageService.get(@storageKey) || {}

    setStoredFilters: (scope) ->
      filters = {}
      for key in @storableFilters
        filters[key] = scope[key]
      localStorageService.set(@storageKey, filters)

    restoreFilters: (scope) ->
      storedFilters = @getStoredFilters()

      unless _.isEmpty(storedFilters)
        for k,v of storedFilters
          scope[k] = v

        return true

      false

    clearFilters: () ->
      localStorageService.remove(@storageKey)
