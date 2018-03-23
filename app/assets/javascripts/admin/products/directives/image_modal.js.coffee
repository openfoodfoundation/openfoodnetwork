angular.module("ofn.admin").directive "imageModal", ($modal, ProductImageService) ->
  restrict: 'C'
  link: (scope, elem, attrs, ctrl) ->
    elem.on "click", (ev) =>
      scope.uploadModal = $modal.open(templateUrl: 'admin/modals/image_upload.html', controller: ctrl, scope: scope, windowClass: 'product-image-upload')
      ProductImageService.configure(scope.product)
