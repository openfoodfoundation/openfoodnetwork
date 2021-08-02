angular.module('Darkswarm').controller "ProducerNodeCtrl", ($scope, HashNavigation, $anchorScroll, $http, $timeout) ->
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

    if $scope.enterprise_details[$scope.producer.id]
      $scope.producer = $scope.enterprise_details[$scope.producer.id]
      $scope.toggle_tab(event)
      return

    $scope.load_shopfront(event)

  $scope.load_shopfront = (event=null) ->
    $scope.shopfront_loading = true
    $scope.toggle_tab(event)

    $http.get("/api/v0/shops/" + $scope.producer.id)
      .then (response) ->
        $scope.shopfront_loading = false
        $scope.producer = response.data
        $scope.enterprise_details[$scope.producer.id] = $scope.producer
      .catch (response) ->
        console.error(response.data)

  $scope.toggle_tab = (event) ->
    HashNavigation.toggle $scope.producer.hash if event && !angular.element(event.target).inheritedData('is-link')

  $scope.open = ->
    HashNavigation.active($scope.producer.hash)

  if $scope.open()
    $anchorScroll()
