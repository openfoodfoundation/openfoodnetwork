Darkswarm.controller "ProducerNodeCtrl", ($scope, HashNavigation, $anchorScroll, $http) ->
  $scope.shopfront_loading = false
  $scope.enterprise_details = []

  # Toggles shopfront tabs open/closed. Fetches enterprise details from the api, diplays them and adds them
  # to $scope.enterprise_details, or simply displays the details again if previously fetched
  $scope.toggle = (event) ->
    if $scope.open()
      $scope.toggle_tab(event)
      return

    if $scope.enterprise_details[$scope.producer.id]
      $scope.producer = $scope.enterprise_details[$scope.producer.id]
      $scope.toggle_tab(event)
      return

    $scope.shopfront_loading = true
    $scope.toggle_tab(event)

    $http.get("/api/enterprises/" + $scope.producer.id + "/shopfront")
      .success (data) ->
        $scope.shopfront_loading = false
        $scope.producer = data
        $scope.enterprise_details[$scope.producer.id] = $scope.producer
      .error (data) ->
        console.error(data)

  $scope.toggle_tab = (event) ->
    HashNavigation.toggle $scope.producer.hash if !angular.element(event.target).inheritedData('is-link')

  $scope.open = ->
    HashNavigation.active($scope.producer.hash)

  if $scope.open()
    $anchorScroll()
