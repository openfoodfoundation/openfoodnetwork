angular.module('Darkswarm').filter 'showHubProfiles', ()->
  # Filter hub_profile enterprises in or out.
  (enterprises, show_profiles) ->
    enterprises ||= []
    show_profiles ?= false

    enterprises.filter (enterprise)=>
      show_profiles or enterprise.is_distributor
