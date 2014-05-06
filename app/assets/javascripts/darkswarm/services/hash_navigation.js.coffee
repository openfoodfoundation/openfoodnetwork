Darkswarm.factory 'HashNavigation', ($location) ->
  new class HashNavigation
    hash: null 

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
