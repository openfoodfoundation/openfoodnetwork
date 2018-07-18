angular.module("admin.subscriptions").factory 'CustomerResource', ($resource) ->
  $resource '/admin/customers/:id.json'
