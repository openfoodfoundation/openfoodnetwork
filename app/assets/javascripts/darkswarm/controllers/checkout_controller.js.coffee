Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage) ->
  window.tmp = $scope
  $scope.order = $scope.Order = Order

  storage.bind $scope, "user", { defaultValue: true}
  $scope.disable = ->
    $scope.user = false
    $scope.details = true

  storage.bind $scope, "details"
  storage.bind $scope, "billing"
  storage.bind $scope, "shipping"
  storage.bind $scope, "payment"

  # Validation utilities to keep things DRY
  $scope.dirtyValid = (name)->
    $scope.dirty(name) and $scope.valid(name) 
  $scope.dirty = (name)->
    $scope.checkout[name].$dirty
  $scope.valid = (name)->
    $scope.checkout[name].$invalid
  $scope.error = (name)->
    $scope.checkout[name].$error
  $scope.required = (name)->
    $scope.error(name).required
  $scope.email = (name)->
    $scope.error(name).email
  $scope.number = (name)->
    $scope.error(name).number

Darkswarm.controller "DetailsSubCtrl", ($scope) ->
  $scope.detailsValid = ->
    $scope.detailsFields().every (field)->
      $scope.checkout[field].$valid
    
  $scope.detailsFields = ->
    ["order[email]",
      "order[bill_address_attributes][phone]",
      "order[bill_address_attributes][firstname]",
      "order[bill_address_attributes][lastname]"]
  
  $scope.emailName = 'order[email]' 
  $scope.emailValid = ->
    $scope.dirtyValid($scope.emailName)
  $scope.emailError = ->
    return "can't be blank" if $scope.required($scope.emailName)
    return "must be valid" if $scope.email($scope.emailName)

  $scope.phoneName = "order[bill_address_attributes][phone]"
  $scope.phoneValid = ->
    $scope.dirtyValid($scope.phoneName)
  $scope.phoneError = ->
    "must be a number"

  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()


