angular.module("admin.businessModelConfiguration").controller "BusinessModelConfigCtrl", ($scope, $filter) ->
  $scope.turnover = 1000

  $scope.bill = ->
    return $filter('currency')(0) unless $scope.fixed || $scope.rate
    Number($scope.fixed) + Number($scope.turnover) * Number($scope.rate)

  $scope.cappedBill = ->
    return $scope.bill() if !$scope.cap? || Number($scope.cap) == 0
    Math.min($scope.bill(), Number($scope.cap))

  $scope.finalBill = ->
    return 0 if Number($scope.turnover) < Number($scope.minBillableTurnover)
    $scope.cappedBill()

  $scope.capReached = ->
    return t('no') if !$scope.cap? || Number($scope.cap) == 0
    if $scope.bill() >= Number($scope.cap) then t('yes') else t('no')

  $scope.includedTax = ->
    return 0 if !$scope.taxRate? || Number($scope.taxRate) == 0
    ($scope.cappedBill() * Number($scope.taxRate))

  $scope.total = ->
    $scope.finalBill() + $scope.includedTax()
