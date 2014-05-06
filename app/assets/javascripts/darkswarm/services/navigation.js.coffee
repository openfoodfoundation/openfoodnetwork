Darkswarm.factory 'Navigation', ($location) ->
  new class Navigation
    path: null 

    active: (path)->
      $location.path() == path 

    navigate: (path)->
      @path = path
      $location.path(@path)

    toggle: (path = false)->
      @path = path || @path
      if $location.path() == @path
        $location.path("/")
      else
        @navigate(path)

    go: (path)->
      window.location.pathname = path
