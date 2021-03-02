window.OFNShared = angular.module("OFNShared", [
  
]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
