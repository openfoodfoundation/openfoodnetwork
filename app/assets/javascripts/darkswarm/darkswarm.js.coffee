window.Darkswarm = angular.module("Darkswarm", ["ngResource", "filters", 'mm.foundation']).config ($httpProvider, $tooltipProvider) ->
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content') 
  $httpProvider.defaults.headers['common']['X-Requested-With'] = 'XMLHttpRequest' 
  $httpProvider.defaults.headers.common.Accept = "application/json, text/javascript, */*"

  # This allows us to trigger these two events on tooltips
  $tooltipProvider.setTriggers( 'openTrigger': 'closeTrigger' )
