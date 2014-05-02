Darkswarm.factory 'Navigation', ($location) ->
  new class Navigation
    paths: []
    path: null 

    navigate: (path = false)->
      @path = path || @path || @paths[0] 
      if $location.path() == @path
        $location.path("/")
      else
        $location.path(@path)

    go: (path)->
      window.location.pathname = path
