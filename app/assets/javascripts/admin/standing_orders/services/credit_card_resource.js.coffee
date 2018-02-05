angular.module("admin.standingOrders").factory 'CreditCardResource', ($resource) ->
  resource = $resource '/admin/customers/:customer_id/cards.json', {},
    'index':
      method: 'GET'
      isArray: true
