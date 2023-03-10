angular.module("ofn.admin", [
  "ngResource",
  "mm.foundation",
  "angularFileUpload",
  "ngAnimate",
  "admin.utils",
  "admin.indexUtils",
  "admin.dropdown",
  "admin.products",
  "admin.taxons",
  "infinite-scroll",
  "admin.orders"
]).config ($httpProvider, $locationProvider, $qProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
  # for the next line, you should also probably check file: app/assets/javascripts/admin/utils/utils.js.coffee
  $locationProvider.hashPrefix('')
  $qProvider.errorOnUnhandledRejections(false)
