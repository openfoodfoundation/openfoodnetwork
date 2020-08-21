angular.module("ofn.admin").factory "ProductFiltersUrl", ($httpParamSerializer) ->
  new class ProductFiltersUrl
    productFilters: ['producerFilter', 'categoryFilter', 'query', 'sorting', 'importDateFilter']

    loadFromUrl: (filters) ->
      loadedFilters = {}
      for filter in @productFilters
        loadedFilters[filter] = if filters[filter] then filters[filter] else ""

      loadedFilters

    generate: (ctrlFilters) ->
      filters = {}
      for filter in @productFilters
        filters[filter] = ctrlFilters[filter] if ctrlFilters[filter]

      filters

    buildUrl: (baseUrl, ctrlFilters) ->
      filterUrl = $httpParamSerializer(@generate(ctrlFilters))
      filterUrl = "?#{filterUrl}" if filterUrl isnt ""

      "#{baseUrl}#{filterUrl}"
