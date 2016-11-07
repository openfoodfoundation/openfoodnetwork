window.Darkswarm = angular.module("Darkswarm", ["ngResource",
  'mm.foundation',
  'LocalStorageModule',
  'infinite-scroll',
  'angular-flash.service',
  'templates',
  'ngSanitize',
  'ngAnimate',
  'google-maps',
  'duScroll',
  'angularFileUpload',
  'angularSlideables'
  ]).config ($httpProvider, $tooltipProvider, $locationProvider, $anchorScrollProvider) ->
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')
  $httpProvider.defaults.headers.put['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')
  $httpProvider.defaults.headers['common']['X-Requested-With'] = 'XMLHttpRequest'
  $httpProvider.defaults.headers.common.Accept = "application/json, text/javascript, */*"

  # This allows us to trigger these two events on tooltips
  $tooltipProvider.setTriggers( 'openTrigger': 'closeTrigger' )

  # We manually handle our scrolling
  $anchorScrollProvider.disableAutoScrolling()
