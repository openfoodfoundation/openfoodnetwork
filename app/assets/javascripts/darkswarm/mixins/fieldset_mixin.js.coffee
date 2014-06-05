window.FieldsetMixin = ($scope)->
  $scope.next = (event = false)->
    event.preventDefault() if event
    $scope.show $scope.nextPanel 

  $scope.onTimeout = ->
    if $scope[$scope.name].$valid
      $scope.next()

  $scope.valid = ->
    $scope.form().$valid

  $scope.form = ->
    $scope[$scope.name]

  $scope.field = (path)->
    $scope.form()[path]

  $scope.fieldValid = (path)->
    not ($scope.dirty(path) and $scope.invalid(path))

  $scope.dirty = (name)->
    $scope.field(name).$dirty

  $scope.invalid = (name)->
    $scope.field(name).$invalid

  $scope.error = (name)->
    $scope.field(name).$error

  $scope.fieldErrors = (path)->
    errors = for error, invalid of $scope.error(path)
      if invalid
        switch error
          when "required" then "can't be blank"
          when "number"   then "must be number"
          when "email"    then "must be email address"

    #server_errors = $scope.Order.errors[path.replace('order.', '')] 
    #errors.push server_errors if server_errors? 
    (errors.filter (error) -> error?).join ", "
    
