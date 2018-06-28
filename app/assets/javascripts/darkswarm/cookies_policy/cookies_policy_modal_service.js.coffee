Darkswarm.factory "CookiesPolicyModalService", (Navigation, $modal, $location, CookiesBannerService)->

  new class CookiesPolicyModalService
    defaultPath: "/policies/cookies"
    modalMessage: null

    constructor: ->
      if $location.path() is @defaultPath || location.pathname is @defaultPath
        @open ''

    open: (path = false, template = 'darkswarm/cookies_policy/cookies_policy.html') =>
      @modalInstance = $modal.open
        templateUrl: template
        windowClass: "cookies-policy-modal medium"

      @closeCookiesBanner()
      @onCloseReOpenCookiesBanner()

      selectedPath = path || @defaultPath
      Navigation.navigate selectedPath

    closeCookiesBanner: =>
      setTimeout ->
        CookiesBannerService.close()
      , 200

    onCloseReOpenCookiesBanner: =>
      @modalInstance.result.then(
        -> CookiesBannerService.open(),
        -> CookiesBannerService.open() )
