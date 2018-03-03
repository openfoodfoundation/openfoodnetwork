Darkswarm.factory "AuthenticationService", (Navigation, $modal, $location, Redirections, Loading)->

  new class AuthenticationService
    selectedPath: "/login"

    constructor: ->
      if $location.path() in ["/login", "/signup", "/forgot"] || location.pathname is '/register/auth'
        @open @initialTab(), @initialTemplate()

    open: (path = false, template = 'authentication.html') =>
      @modalInstance = $modal.open
        templateUrl: template
        windowClass: "login-modal medium"
      @modalInstance.result.then @close, @close
      @selectedPath = path || @selectedPath
      Navigation.navigate @selectedPath

    initialTab: ->
      if angular.isDefined($location.search()['validation'])
        '/login'
      else if location.pathname is '/register/auth'
        '/signup'
      else
        $location.path()

    initialTemplate: ->
      if location.pathname is '/register/auth'
        'registration_authentication.html'
      else
        'authentication.html'

    select: (path)=>
      @selectedPath = path
      Navigation.navigate @selectedPath

    isActive: Navigation.isActive

    close: ->
      if location.pathname in ["/register", "/register/auth"]
        Loading.message = t 'going_back_to_home_page'
        location.hash = ""
        location.pathname = "/"
