angular.module('admin.enterpriseFees').controller 'enterpriseFeesCtrl', ($scope, $http, $window) ->
  $scope.enterpriseFeesUrl = ->
    url = '/admin/enterprise_fees.json?include_calculators=1'
    match = $window.location.search.match(/enterprise_id=(\d+)/)
    if match
      url += '&' + match[0]
    url

  $http.get($scope.enterpriseFeesUrl()).success (data) ->
    $scope.enterprise_fees = data
    # TODO: Angular 1.1.0 will have a means to reset a form to its pristine state, which
    #       would avoid the need to save off original calculator types for comparison.
    for i of $scope.enterprise_fees
      $scope.enterprise_fees[i].orig_calculator_type = $scope.enterprise_fees[i].calculator_type
    return

  return
