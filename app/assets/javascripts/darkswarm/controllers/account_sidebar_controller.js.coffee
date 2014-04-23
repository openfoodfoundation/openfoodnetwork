window.AccountSidebarCtrl = Darkswarm.controller "AccountSidebarCtrl", ($scope, $http, $location, SpreeUser, Navigation) ->
  $scope.path = "/account"
  Navigation.paths.push $scope.path

  $scope.active = ->
    $location.path() == $scope.path

  $scope.select = ->
    Navigation.navigate($scope.path)

  $scope.emptyCart = (href, ev)->
    if $(ev.delegateTarget).hasClass "empties-cart"
      location.href = href if confirm "Changing your Hub will clear your cart."
    else
      location.href = href
