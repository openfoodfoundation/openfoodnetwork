angular.module('Darkswarm').factory "RegistrationService", (Navigation, $modal, Loading)->

  new class RegistrationService
    constructor: ->
      @open()

    open: =>
      @modalInstance = $modal.open
        templateUrl: 'registration.html'
        windowClass: "login-modal large"
        backdrop: 'static'
      @modalInstance.result.then @close, @close
      @select 'introduction'

    select: (step)=>
      @current_step = step

    currentStep: =>
      @current_step

    close: ->
      Loading.message = t 'going_back_to_home_page'
      Navigation.go "/"
