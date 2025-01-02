window.OFNShared = angular.module("OFNShared", [
  "mm.foundation",
]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
