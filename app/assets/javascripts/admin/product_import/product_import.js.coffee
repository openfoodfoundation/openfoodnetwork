angular.module("admin.productImport", ["ngResource"]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
