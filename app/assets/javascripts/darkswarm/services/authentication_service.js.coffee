# This class deals with displaying things in the login modal. It chooses
# the modal tab templates and deals with switching tabs and passing data
# between the tabs. It has direct access to the instance of the login modal,
# and provides that access to other controllers as a service.

angular.module('Darkswarm').factory "AuthenticationService", (Navigation, $modal, $location, Redirections, Loading)->

  new class AuthenticationService
    selectedPath: "/login"
    modalMessage: null

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

      if window._paq
        window._paq.push(['trackEvent', 'Signin/Signup', 'Login Modal View', window.location.href])

    # Opens the /login tab if returning from email confirmation,
    # the /signup tab if opened from the enterprise registration page,
    # otherwise opens whichever tab is selected in the URL params ('/login', '/signup', or '/forgot')
    initialTab: ->
      if angular.isDefined($location.search()['validation'])
        '/login'
      else if location.pathname is '/register/auth'
        '/signup'
      else
        $location.path()

    # Loads the registration page modal when needed, otherwise the default modal
    initialTemplate: ->
      if location.pathname is '/register/auth'
        'registration_authentication.html'
      else
        'authentication.html'
    pushMessage: (message) ->
      @modalMessage = String(message)

    select: (path)=>
      @selectedPath = path
      Navigation.navigate @selectedPath

    isActive: Navigation.isActive

    close: ->
      if location.pathname in ["/register", "/register/auth"]
        Loading.message = t 'going_back_to_home_page'
        location.hash = ""
        location.pathname = "/"
