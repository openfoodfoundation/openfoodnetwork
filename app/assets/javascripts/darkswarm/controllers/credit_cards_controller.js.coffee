Darkswarm.controller "CreditCardsCtrl", ($scope, CreditCard, CreditCards) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.savedCreditCards = CreditCards.saved
  $scope.setDefault = CreditCards.setDefault
  $scope.CreditCard = CreditCard
  $scope.secrets = CreditCard.secrets
  $scope.showForm = CreditCard.show
  $scope.storeCard = ->
    if $scope.new_card_form.$valid
      CreditCard.requestToken()

  $scope.allow_name_change = true
  $scope.disable_fields = false
