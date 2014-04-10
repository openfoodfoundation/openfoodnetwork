window.FieldsetMixin = ($scope)->
  $scope.field = (path)->
    $scope[$scope.name][path]

  $scope.fieldValid = (path)->
    not ($scope.dirty(path) and $scope.invalid(path))

  $scope.dirty = (name)->
    $scope.field(name).$dirty

  $scope.invalid = (name)->
    $scope.field(name).$invalid

  $scope.error = (name)->
    $scope.field(name).$error

  $scope.fieldErrors = (path)->
    # TODO: display server errors
    errors = for error, invalid of $scope.error(path)
      if invalid
        switch error
          when "required" then "must not be blank"
          when "number"   then "must be number"
          when "email"    then "must be email address"
    (errors.filter (error) -> error?).join ", "



