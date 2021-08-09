angular.module('Darkswarm').controller "PageSelectionCtrl", ($scope, $rootScope, $location) ->
  $scope.selectedPage = ->
    # The path looks like `/contact` for the URL `https://ofn.org/shop#/contact`.
    # We remove the slash at the beginning.
    page = $location.path()[1..]

    return $scope.whitelist[0] unless page

    # If the path points to an unrelated path like `/login`, stay where we were.
    return $scope.lastPage unless page in $scope.whitelist

    $scope.lastPage = page
    page

  $scope.whitelistPages = (pages) ->
    $scope.whitelist = pages
    $scope.lastPage = pages[0]

  # when an order cycle is changed, ensure the shop tab is active to save a click
  $rootScope.$on "orderCycleSelected", ->
    if $scope.selectedPage() != "shop"
      $location.path("shop")
