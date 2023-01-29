angular.module('Darkswarm').controller "CreditCardsCtrl", ($scope, $http, CreditCard, CreditCards, $controller) ->
  angular.extend this, $controller('FieldsetMixin', {$scope: $scope})

  $scope.savedCreditCards = CreditCards.saved
  $scope.confirmSetDefault = CreditCards.confirmSetDefault
  $scope.CreditCard = CreditCard
  $scope.secrets = CreditCard.secrets
  $scope.showForm = CreditCard.show
  $scope.storeCard = ->
    if $scope.new_card_form.$valid
      CreditCard.requestToken()

  $scope.allow_name_change = true
  $scope.disable_fields = false

  $scope.deleteCard = (id) ->
    $http(
      method: "DELETE"
      url: "/credit_cards/#{id}"
    ).finally ->
      window.location.reload()


  $scope.hasOneDefaultSavedCards = () ->
    $scope.savedCreditCards.some((card) -> card.is_default)
