Darkswarm.factory "AuthenticationService", (Navigation, $modal, $location, Redirections)->
  new class AuthenticationService
    selectedPath: "/login"

    constructor: ->
      if $location.path() in ["/login", "/signup", "/forgot"] 
        @open()

    open: (path = false)=>
      @modalInstance = $modal.open
        templateUrl: 'authentication.html'
        windowClass: "login-modal medium"
      @modalInstance.result.then @close, @close
      @selectedPath = path || @selectedPath
      Navigation.navigate @selectedPath


    select: (path)=>
      @selectedPath = path
      Navigation.navigate @selectedPath

    active: Navigation.active

    close: ->
      Navigation.navigate "/"
