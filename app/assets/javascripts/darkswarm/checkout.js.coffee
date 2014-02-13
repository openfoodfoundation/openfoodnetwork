window.Checkout = angular.module("Checkout", ["ngResource", "filters"]).config ($httpProvider) ->
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content') 
