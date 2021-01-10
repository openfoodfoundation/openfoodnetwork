angular.module("admin.utils", ["templates", "ngSanitize"]).config ($httpProvider) ->
 $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
