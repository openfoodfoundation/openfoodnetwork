angular.module('Darkswarm').controller "EnterpriseImageCtrl", ($scope, EnterpriseImageService) ->
  $scope.imageStep = 'logo'

  $scope.imageSteps = ['logo', 'promo']

  $scope.imageUploader = EnterpriseImageService.imageUploader

  $scope.imageSelect = (image_step) ->
    EnterpriseImageService.imageSrc = null
    $scope.imageStep = image_step

  $scope.imageSrc = ->
    EnterpriseImageService.imageSrc
