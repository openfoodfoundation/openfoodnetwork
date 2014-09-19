Darkswarm.factory "EnterpriseImageService", (FileUploader, spreeApiKey) ->
  new class EnterpriseImageService
    imageSrc: null

    imageUploader: new FileUploader
      headers:
        'X-Spree-Token': spreeApiKey
      autoUpload: true

    configure: (enterprise) =>
      @imageUploader.url = "/api/enterprises/#{enterprise.id}/update_image"
      @imageUploader.onSuccessItem = (image, response) => @imageSrc = response
