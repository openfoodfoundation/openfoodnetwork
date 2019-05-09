Darkswarm.controller "HubNodeCtrl", ($scope, HashNavigation, Navigation, $location, $templateCache, CurrentHub, $http) ->
  $scope.shopfront_loading = false
  $scope.enterprise_details = []

  # Toggles shopfront tabs open/closed. Fetches enterprise details from the api, diplays them and adds them
  # to $scope.enterprise_details, or simply displays the details again if previously fetched
  $scope.toggle = (event) ->
    if $scope.open()
      $scope.toggle_tab(event)
      return

    if $scope.enterprise_details[$scope.hub.id]
      $scope.hub = $scope.enterprise_details[$scope.hub.id]
      $scope.toggle_tab(event)
      return

    $scope.shopfront_loading = true
    $scope.toggle_tab(event)

    $http.get("/api/enterprises/" + $scope.hub.id + "/shopfront")
      .success (data) ->
        $scope.shopfront_loading = false
        $scope.hub = data
        $scope.enterprise_details[$scope.hub.id] = $scope.hub
      .error (data) ->
        console.error(data)

  $scope.toggle_tab = (event) ->
    HashNavigation.toggle $scope.hub.hash if !angular.element(event.target).inheritedData('is-link')

  # Returns boolean: pulldown tab is currently open/closed
  $scope.open = ->
    HashNavigation.active $scope.hub.hash

  # Returns boolean: is this hub the hub that the user is currently "shopping" in?
  $scope.current = ->
    $scope.hub.id is CurrentHub.hub.id
