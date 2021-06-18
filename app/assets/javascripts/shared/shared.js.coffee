window.OFNShared = angular.module("OFNShared", [
  "mm.foundation",
  "LocalStorageModule"
]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
