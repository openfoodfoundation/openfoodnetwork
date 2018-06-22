describe "PaymentCtrl", ->
  ctrl = null
  scope = null
  card1 = { id: 1, is_default: false }
  card2 = { id: 3, is_default: true }
  cards = [card1, card2]

  beforeEach ->
    module("Darkswarm")
    angular.module('Darkswarm').value('savedCreditCards', cards)
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new()
      scope.secrets = {}
      ctrl = $controller 'PaymentCtrl', {$scope: scope}

  it "sets the default card id as the selected_card", ->
    expect(scope.secrets.selected_card).toEqual card2.id
