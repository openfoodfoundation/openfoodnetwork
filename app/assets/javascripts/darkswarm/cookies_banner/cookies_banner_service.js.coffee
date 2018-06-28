Darkswarm.factory "CookiesBannerService", (Navigation, $modal, $location, Redirections, Loading)->

  new class CookiesBannerService
    modalMessage: null
    isActive: false

    open: (path, template = 'darkswarm/cookies_banner/cookies_banner.html') =>
      return unless @isActive
      @modalInstance = $modal.open
        templateUrl: template
        windowClass: "cookies-banner full"
        backdrop: 'static'
        keyboard: false

    close: =>
      return unless @isActive
      @modalInstance.close()

    setActive: =>
      @isActive = true
