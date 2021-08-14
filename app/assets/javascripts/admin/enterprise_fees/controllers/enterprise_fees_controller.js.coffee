angular.module('admin.enterpriseFees').controller 'enterpriseFeesCtrl', ($scope, $http, $window, enterprises, tax_categories, calculators) ->
  $scope.enterprises = enterprises
  $scope.tax_categories =  [{id: -1, name: t('js.admin.enterprise_fees.inherit_from_product') }].concat tax_categories
  $scope.calculators = calculators

  $scope.enterpriseFeesUrl = ->
    url = '/admin/enterprise_fees.json?include_calculators=1'
    match = $window.location.search.match(/enterprise_id=(\d+)/)
    if match
      url += '&' + match[0]
    url

  $http.get($scope.enterpriseFeesUrl()).then (response) ->
    $scope.enterprise_fees = response.data
