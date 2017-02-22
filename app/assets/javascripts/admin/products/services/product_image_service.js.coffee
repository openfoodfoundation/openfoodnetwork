angular.module("ofn.admin").factory "ProductImageService", (FileUploader, SpreeApiKey) ->
  new class ProductImageService
    imagePreview: null

    imageUploader: new FileUploader
      headers:
        'X-Spree-Token': SpreeApiKey
      autoUpload: true

    configure: (product) =>
      @imageUploader.url = "/api/images/product/#{product.id}"
      @imagePreview = product.image_url
      @imageUploader.onSuccessItem = (image, response) =>
        product.thumb_url = response.thumb_url
        product.image_url = response.image_url
