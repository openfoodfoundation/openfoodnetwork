Darkswarm.factory "AuthenticationService", (Navigation, $modal, $location, Redirections)->

  new class AuthenticationService
    selectedPath: "/login"

    constructor: ->
      if $location.path() in ["/login", "/signup", "/forgot"] && location.pathname isnt '/register/auth'
        @open $location.path()
      else if location.pathname is '/register/auth'
        @open '/signup', 'registration_authentication.html'

    open: (path = false, template = 'authentication.html') =>
      @modalInstance = $modal.open
        templateUrl: template
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
