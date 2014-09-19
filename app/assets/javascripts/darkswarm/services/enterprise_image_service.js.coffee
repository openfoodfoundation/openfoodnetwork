Darkswarm.factory "EnterpriseImageService", (EnterpriseRegistrationService, FileUploader, spreeApiKey) ->
  new class EnterpriseImageService
    imageSrc: null

    imageUploader: new FileUploader
      headers:
        'X-Spree-Token': spreeApiKey
      url: "/api/enterprises/#{EnterpriseRegistrationService.enterprise.id}/update_image"
      autoUpload: true

    constructor: ->
      @imageUploader.onSuccessItem = (image, response) =>
        @imageSrc = response
