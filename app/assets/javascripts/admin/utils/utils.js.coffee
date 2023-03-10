angular.module("admin.utils", ["templates", "ngSanitize"]).config ($httpProvider, $locationProvider) ->
 # for the next line, you should also probably check file: app/assets/javascripts/admin/admin_ofn.js.coffee
 $locationProvider.hashPrefix('')
 $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
