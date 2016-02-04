angular.module('admin.enterpriseFees').controller 'enterpriseFeesCtrl', ($scope, $http, $window, enterprises, tax_categories, calculators) ->
  $scope.enterprises = enterprises
  $scope.tax_categories =  [{id: -1, name: "Inherit From Product"}].concat tax_categories
  $scope.calculators = calculators

  $scope.enterpriseFeesUrl = ->
    url = '/admin/enterprise_fees.json?include_calculators=1'
    match = $window.location.search.match(/enterprise_id=(\d+)/)
    if match
      url += '&' + match[0]
    url

  $http.get($scope.enterpriseFeesUrl()).success (data) ->
    $scope.enterprise_fees = data
