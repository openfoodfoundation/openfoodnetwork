Darkswarm.controller "PageSelectionCtrl", ($scope, $location) ->
  $scope.selectedPage = ->
    # The path looks like `/contact` for the URL `https://ofn.org/shop#/contact`.
    # We remove the slash at the beginning.
    page = $location.path()[1..]
    if page in $scope.whitelist
      $scope.lastPage = page
      page
    else if page
      # The path points to an unrelated path like `/login`. Stay where we were.
      $scope.lastPage
    else
      $scope.whitelist[0]

  $scope.whitelistPages = (pages) ->
    $scope.whitelist = pages
    $scope.lastPage = pages[0]
