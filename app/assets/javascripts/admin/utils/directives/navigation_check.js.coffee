angular.module("admin.utils").directive "navCheck", (NavigationCheck)->
  restrict: 'A'
  scope:
    navCallback: '&'
  link: (scope,element,attributes) ->
    # Define navigationCallback on a controller in scope, otherwise this default will be used:
    scope.navCallback ||= ->
      "You will lose any unsaved work!"
    NavigationCheck.register(scope.navCallback)
