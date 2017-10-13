Darkswarm.controller "CreditCardsCtrl", ($scope, $timeout, CreditCard, CreditCards, Dates) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.savedCreditCards = CreditCards.saved
  $scope.CreditCard = CreditCard
  $scope.secrets = CreditCard.secrets
  $scope.showForm = CreditCard.show
  $scope.storeCard = ->
    if $scope.new_card_form.$valid
      CreditCard.requestToken()

  $scope.allow_name_change = true
  $scope.disable_fields = false
