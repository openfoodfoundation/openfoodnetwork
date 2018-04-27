angular.module("Darkswarm").factory 'Customer', ($resource, RailsFlashLoader) ->
  Customer = $resource('/api/customers/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
      params:
        id: '@id'
      transformRequest: (data, headersGetter) ->
        angular.toJson(customer: data)
  })

  Customer.prototype.update = ->
    @$update().then (response) =>
      RailsFlashLoader.loadFlash({success: t('js.changes_saved')})
    , (response) =>
      RailsFlashLoader.loadFlash({error: response.data.error})

  Customer
