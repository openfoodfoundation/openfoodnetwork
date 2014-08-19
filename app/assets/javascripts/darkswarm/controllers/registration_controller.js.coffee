Darkswarm.controller "RegistrationCtrl", ($scope, $location, AuthenticationService, CurrentUser)->
  if CurrentUser is undefined
    $location.search('after_login', '/register/')
    AuthenticationService.open()

