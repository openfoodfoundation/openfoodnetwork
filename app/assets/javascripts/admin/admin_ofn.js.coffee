angular.module("ofn.admin", ["ngResource", "ngAnimate", "admin.utils", "admin.indexUtils", "admin.dropdown", "admin.products", "admin.taxons", "infinite-scroll"]).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content")
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*"
