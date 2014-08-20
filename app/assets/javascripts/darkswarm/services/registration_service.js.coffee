Darkswarm.factory "RegistrationService", (Navigation, $modal, $location)->

  new class RegistrationService
    current_step: 'introduction'

    constructor: ->
      @open()

    open: =>
      @modalInstance = $modal.open
        templateUrl: 'registration.html'
        windowClass: "login-modal large"
      @modalInstance.result.then @close, @close
      @select @current_step

    select: (step)=>
      @current_step = step
      Navigation.navigate '/' + @current_step

    active: Navigation.active
    
    currentStep: =>
      @current_step

    close: ->
      Navigation.navigate "/"