#= require jquery2
#= require jquery.ui.all
#
#= require angular
#= require angular-cookies
#= require angular-sanitize
#= require angular-animate
#= require angular-resource
#= require autocomplete.min.js
#= require leaflet-1.6.0.js
#= require leaflet-providers.js
#= require lodash.underscore.js
# bluebird.js and angular-simple-logger are dependencies of angular-google-maps.js 2.0.0
#= require bluebird.js
#= require angular-simple-logger.min.js
#= require angular-scroll.min.js
#= require angular-google-maps.min.js
#= require ../shared/mm-foundation-tpls-0.9.0-20180826174721.min.js
#= require ../shared/ng-infinite-scroll.min.js
#= require ../shared/angular-local-storage.js
#= require ../shared/angular-slideables.js
#= require ../shared/shared
#= require_tree ../shared/directives
#= require angularjs-file-upload
#= require i18n/translations

#= require angular-rails-templates
#= require_tree ../templates
#
#= require angular-flash.min.js
#
#= require modernizr
#
#= require foundation-sites/js/foundation.js
#= require ./darkswarm
#= require_tree ./mixins
#= require_tree ./directives
#= require_tree .

document.addEventListener "turbo:load", ->
  try
    window.injector = angular.bootstrap document.body, ["Darkswarm"]
  true

document.addEventListener "turbo:before-render", ->
  if window.injector
    rootscope = window.injector.get("$rootScope")
    rootscope?.$destroy()
    rootscope = null
    window.injector = null
  true
