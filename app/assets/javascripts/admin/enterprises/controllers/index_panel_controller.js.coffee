angular.module("admin.enterprises").controller 'indexPanelCtrl', ($scope, Enterprises) ->
  $scope.enterprise = $scope.object
  $scope.saving = false

  $scope.saved = ->
    Enterprises.saved($scope.enterprise)

  $scope.save = ->
    unless $scope.saved()
      $scope.saving = true
      Enterprises.save($scope.enterprise).then (data) ->
        $scope.$emit("enterprise:updated", $scope.enterprise)
        $scope.saving = false
      , (response) ->
        $scope.saving = false
        if response.status == 422 && response.data.errors?
          message = t('js.resolve_errors') + ':\n'
          for attr, msg of response.data.errors
            message += "#{attr} #{msg}\n"
          alert(message)

  $scope.resetAttribute = (attribute) ->
    Enterprises.resetAttribute($scope.enterprise, attribute)
