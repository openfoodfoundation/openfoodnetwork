angular.module('Darkswarm').factory 'CurrentHub', (currentHub) ->
  # Populate CurrentHub.hub from json in page. This is probably redundant now.
  new class CurrentHub
    hub: currentHub
