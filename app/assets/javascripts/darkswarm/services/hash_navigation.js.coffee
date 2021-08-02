angular.module('Darkswarm').factory 'HashNavigation', ($location) ->
  new class HashNavigation
    hash: null

    constructor: ->
      # Make sure we have a path as hashes
      # dont seem to work so well without them
      $location.path("") if !$location.path()

    active: (hash)->
      $location.hash() == hash

    navigate: (hash)->
      @hash = hash
      $location.hash(@hash)

    toggle: (hash = false)->
      @hash = hash || @hash
      if $location.hash() == @hash
        $location.hash("")
      else
        @navigate(hash)
