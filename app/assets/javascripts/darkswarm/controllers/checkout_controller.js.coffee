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


  $scope.fieldValid = (path)->
    not ($scope.dirty(path) and $scope.invalid(path))
  $scope.field = (path)->
    $scope.checkout[path]
  $scope.dirty = (name)->
    $scope.field(name).$dirty
  $scope.invalid = (name)->
    $scope.field(name).$invalid
  $scope.error = (name)->
    $scope.checkout[name].$error
  $scope.fieldErrors = (path)->
    errors = for error, invalid of $scope.error(path)
      if invalid
        switch error
          when "required" then "must not be blank"
          when "number"   then "must be number"
          when "email"    then "must be email address"
    (errors.filter (error) -> error?).join ", "

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()


Darkswarm.controller "DetailsSubCtrl", ($scope) ->
  #$scope.detailsValid = ->
    #$scope.detailsFields().every (field)->
      #$scope.checkout[field].$valid
  
  #$scope.$watch ->
    #$scope.detailsValid()
  #, (valid)->
    #if valid
      #$scope.show("billing")
    
