angular.module('Darkswarm').controller "HubNodeCtrl", ($scope, HashNavigation, CurrentHub, $http, $timeout) ->
  $scope.shopfront_loading = false
  $scope.enterprise_details = []

  $timeout ->
    if $scope.open()
      $scope.load_shopfront()

  # Toggles shopfront tabs open/closed. Fetches enterprise details from the api, diplays them and adds them
  # to $scope.enterprise_details, or simply displays the details again if previously fetched
  $scope.toggle = (event) ->
    return if event.target.closest("a")

    if $scope.open()
      $scope.toggle_tab(event)
      return

    if $scope.enterprise_details[$scope.hub.id]
      $scope.hub = $scope.enterprise_details[$scope.hub.id]
      $scope.toggle_tab(event)
      return

    $scope.load_shopfront(event)

  $scope.load_shopfront = (event=null) ->
    $scope.shopfront_loading = true
    $scope.toggle_tab(event)

    $http.get("/api/v0/shops/" + $scope.hub.id)
      .then (response) ->
        $scope.shopfront_loading = false
        $scope.hub = response.data
        $scope.enterprise_details[$scope.hub.id] = $scope.hub
      .catch (response) ->
        console.error(response.data)

  $scope.toggle_tab = (event) ->
    HashNavigation.toggle $scope.hub.hash if event && !angular.element(event.target).inheritedData('is-link')

  # Returns boolean: pulldown tab is currently open/closed
  $scope.open = ->
    HashNavigation.active $scope.hub.hash

  # Returns boolean: is this hub the hub that the user is currently "shopping" in?
  $scope.current = ->
    $scope.hub.id is CurrentHub.hub.id
