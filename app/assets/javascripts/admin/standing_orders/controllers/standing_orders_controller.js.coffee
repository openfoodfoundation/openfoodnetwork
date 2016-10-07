angular.module("admin.standingOrders").controller "StandingOrdersController", ($scope, StandingOrders, Columns, shops) ->
  $scope.columns = Columns.columns
  $scope.shops = shops
  $scope.shop_id = if shops.length == 1 then shops[0].id else null

  $scope.$watch "shop_id", ->
    if $scope.shop_id?
      # CurrentShop.shop = $filter('filter')($scope.shops, {id: $scope.shop_id})[0]
      $scope.standingOrders = StandingOrders.index("q[shop_id_eq]": $scope.shop_id, ams_prefix: 'index')
