angular.module('Darkswarm').directive 'cookiesBanner', (CookiesBannerService, CookiesPolicyModalService) ->
  restrict: 'A'
  link: (scope, elm, attr)->
    return if not attr.cookiesBanner? || attr.cookiesBanner == 'false'
    CookiesBannerService.enable()
    return if CookiesPolicyModalService.isEnabled()
    CookiesBannerService.open()
