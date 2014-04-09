Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage) ->
  window.tmp = $scope
  $scope.Order = Order
  $scope.order = Order.order 
  $scope.accordion = {}

  $scope.show = (name)->
    $scope.accordion[name] = true

  storage.bind $scope, "accordion.user", { defaultValue: true}
  storage.bind $scope, "accordion.details"
  storage.bind $scope, "accordion.billing"
  storage.bind $scope, "accordion.shipping"
  storage.bind $scope, "accordion.payment"

  # Validation utilities to keep things DRY
  $scope.dirtyInvalid = (name)->
    $scope.dirty(name) and $scope.invalid(name) 
  $scope.dirty = (name)->
    $scope.checkout[name].$dirty
  $scope.invalid = (name)->
    $scope.checkout[name].$invalid

  # Validations
  $scope.error = (name)->
    $scope.checkout[name].$error
  $scope.required = (name)->
    $scope.error(name).required
  $scope.email = (name)->
    $scope.error(name).email
  $scope.number = (name)->
    $scope.error(name).number

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()


# READ THIS FIRST
# https://github.com/angular/angular.js/wiki/Understanding-Scopes

Darkswarm.controller "DetailsSubCtrl", ($scope) ->
  $scope.detailsValid = ->
    $scope.detailsFields().every (field)->
      $scope.checkout[field].$valid
  
  $scope.$watch ->
    $scope.detailsValid()
  , (valid)->
    if valid
      $scope.show("billing")
    
  $scope.detailsFields = ->

    {"order[email]" : {email: "must be email", required: "field required"}}

    ["order[email]",
      "order[bill_address_attributes][phone]",
      "order[bill_address_attributes][firstname]",
      "order[bill_address_attributes][lastname]"]
  
  $scope.emailName = 'order[email]' 
  $scope.emailValid = ->
    $scope.dirtyInvalid($scope.emailName)
  $scope.emailError = ->
    return "can't be blank" if $scope.required($scope.emailName)
    return "must be valid" if $scope.email($scope.emailName)

  $scope.phoneName = "order[bill_address_attributes][phone]"
  $scope.phoneValid = ->
    $scope.dirtyInvalid($scope.phoneName)
  $scope.phoneError = ->
    "must be a number"



