angular.module("Darkswarm").factory 'Customer', ($resource, Messages) ->
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
      Messages.success(t('js.changes_saved'))
    , (response) =>
      Messages.error(response.data.error)

  Customer
