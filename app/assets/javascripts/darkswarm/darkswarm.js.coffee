angular.module("Darkswarm", [
  'ngResource',
  'mm.foundation',
  'LocalStorageModule',
  'infinite-scroll',
  'angular-flash.service',
  'templates',
  'ngSanitize',
  'ngAnimate',
  'uiGmapgoogle-maps',
  'duScroll',
  'angularFileUpload',
  'angularSlideables',
  'OFNShared'
]).config ($httpProvider, $tooltipProvider, $locationProvider, $anchorScrollProvider, $qProvider) ->
  $httpProvider.defaults.headers['common']['X-Requested-With'] = 'XMLHttpRequest'
  $httpProvider.defaults.headers.common['Accept'] = "application/json, text/javascript, */*"
  $locationProvider.hashPrefix('')
  $qProvider.errorOnUnhandledRejections(false)
  # We manually handle our scrolling
  $anchorScrollProvider.disableAutoScrolling()
