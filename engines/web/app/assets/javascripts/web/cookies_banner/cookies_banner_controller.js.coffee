angular.module('Darkswarm').controller "CookiesBannerCtrl", ($scope, CookiesBannerService, $http, $window)->

  $scope.acceptCookies = ->
    $http.post('/api/v0/cookies/consent')
    CookiesBannerService.close()
    CookiesBannerService.disable()
