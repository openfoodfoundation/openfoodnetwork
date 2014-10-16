angular.module("admin.utils").directive "navigationCheck", (NavigationCheck)->
  link: ($scope) ->
    # Define navigationCallback on the controller.
    NavigationCheck.register($scope.navigationCallback)
