Darkswarm.directive 'cookiesBanner', (CookiesBannerService) ->
  restrict: 'A'
  link: (scope, elm, attr)->
    CookiesBannerService.setActive()
    CookiesBannerService.open()
