angular.module('Darkswarm').factory "CookiesBannerService", (Navigation, $modal, $location, Loading)->
  new class CookiesBannerService
    modalMessage: null
    isEnabled: false

    open: (path, template = '/angular-templates/cookies_banner.html') =>
      return unless @isEnabled
      @modalInstance = $modal.open
        templateUrl: template
        windowClass: "cookies-banner full"
        backdrop: 'static'
        keyboard: false

    close: =>
      return unless @isEnabled
      @modalInstance.close()

    enable: =>
      @isEnabled = true

    disable: =>
      @isEnabled = false
