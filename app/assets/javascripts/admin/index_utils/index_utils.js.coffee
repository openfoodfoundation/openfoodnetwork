angular.module("admin.indexUtils", ['admin.resources', 'ngSanitize', 'templates', 'admin.utils']).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content");  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*";
