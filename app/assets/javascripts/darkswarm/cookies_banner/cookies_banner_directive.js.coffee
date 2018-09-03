Darkswarm.directive 'cookiesBanner', (CookiesBannerService) ->
  restrict: 'A'
  link: (scope, elm, attr)->
    return if not attr.cookiesBanner? || attr.cookiesBanner == 'false'
    CookiesBannerService.enable()
    CookiesBannerService.open()
