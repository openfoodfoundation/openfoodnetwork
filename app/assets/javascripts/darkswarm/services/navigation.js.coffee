Darkswarm.factory 'Navigation', ($location, $window) ->
  new class Navigation
    path: null

    isActive: (path)->
      $location.path() == path

    navigate: (path)=>
      @path = path
      $location.path(@path)

    toggle: (path = false)=>
      @path = path || @path
      if $location.path() == @path
        $location.path("/")
      else
        @navigate(path)

    goWithoutHashFragments: (path) ->
      # Redirects to specified path, without Angular hash fragments such as '#/login'
      $window.location.href = $window.location.origin + path

    go: (path)->
      # The browser treats this like clicking on a link.
      # It works for absolute paths, relative paths and URLs alike.
      $window.location.href = path

    reload: ->
      $window.location.reload()
