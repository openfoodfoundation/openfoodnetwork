angular.module("admin.subscriptions").controller "ProductsPanelController", ($scope, Subscriptions, StatusMessage) ->
  $scope.subscription = $scope.object
  $scope.distributor_id = $scope.subscription.shop_id
  $scope.saving = false

  $scope.saved = ->
    pristine = Subscriptions.pristineByID[$scope.subscription.id].subscription_line_items
    return false unless angular.equals($scope.subscription.subscription_line_items, pristine)
    true

  $scope.save = ->
    $scope.saving = true
    StatusMessage.display 'progress', t('js.saving')
    $scope.subscription.update().then (response) ->
      $scope.saving = false
      StatusMessage.display 'success', t('js.changes_saved')
    , (response) ->
      $scope.saving = false
      if response.data?.errors?
        keys = Object.keys(response.data.errors)
        StatusMessage.display 'failure', response.data.errors[keys[0]][0]
      else
        StatusMessage.display 'failure', t('js.admin.subscriptions.error_saving')
