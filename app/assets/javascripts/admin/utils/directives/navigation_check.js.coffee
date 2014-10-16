angular.module("admin.utils").directive "navigationCheck", (NavigationCheck)->
  link: ($scope) ->
    # Define navigationCallback on a controller in $scope, otherwise this default will be used:
    $scope.navigationCallback ||= ->
      "You will lose any unsaved work!"
    NavigationCheck.register($scope.navigationCallback)
