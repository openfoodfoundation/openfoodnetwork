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
  "infinite-scroll"
]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
