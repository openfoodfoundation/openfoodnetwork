Darkswarm.controller "CookiesBannerCtrl", ($scope, CookiesBannerService, $http, $window)->

  $scope.acceptCookies = ->
    $http.post('/web/api/cookies/consent')
    CookiesBannerService.close()
    CookiesBannerService.disable()
