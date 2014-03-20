window.Darkswarm = angular.module("Darkswarm", ["ngResource", "filters"]).config ($httpProvider) ->
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content') 
