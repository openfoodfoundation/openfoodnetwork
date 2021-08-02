angular.module('Darkswarm').factory "CookiesPolicyModalService", (Navigation, $modal, $location, CookiesBannerService)->

  new class CookiesPolicyModalService
    defaultPath: "/policies/cookies"
    modalMessage: null

    constructor: ->
      if @isEnabled()
        @open ''

    open: (path = false, template = '/angular-templates/cookies_policy.html') =>
      @modalInstance = $modal.open
        templateUrl: template
        windowClass: "cookies-policy-modal medium"

      CookiesBannerService.close()
      @onCloseOpenCookiesBanner()

      selectedPath = path || @defaultPath
      Navigation.navigate selectedPath

    onCloseOpenCookiesBanner: =>
      @modalInstance.result.then(
        -> CookiesBannerService.open(),
        -> CookiesBannerService.open() )

    isEnabled: =>
      $location.path() is @defaultPath || location.pathname is @defaultPath
