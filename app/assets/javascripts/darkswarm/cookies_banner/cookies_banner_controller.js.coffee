Darkswarm.controller "CookiesBannerCtrl", ($scope, CookiesBannerService, $http, $window)->

  $scope.acceptCookies = ->
    $http.post('/api/cookies/consent')
    CookiesBannerService.close()
