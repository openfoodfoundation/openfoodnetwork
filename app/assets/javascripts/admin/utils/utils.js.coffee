angular.module("admin.utils", ["templates", "ngSanitize"]).config ($httpProvider, $locationProvider) ->
 $locationProvider.hashPrefix('')
 $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
