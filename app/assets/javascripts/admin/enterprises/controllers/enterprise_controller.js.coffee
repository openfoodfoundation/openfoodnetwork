angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, $http, $window, NavigationCheck, enterprise, Enterprises, SideMenu, StatusMessage, RequestMonitor) ->
    $scope.Enterprise = enterprise
    $scope.Enterprises = Enterprises
    $scope.navClear = NavigationCheck.clear
    $scope.menu = SideMenu
    $scope.StatusMessage = StatusMessage
    $scope.RequestMonitor = RequestMonitor

    $scope.$watch 'enterprise_form.$dirty', (newValue) ->
      StatusMessage.display 'notice', t('admin.unsaved_changes') if newValue

    $scope.setFormDirty = ->
      $scope.$apply ->
        $scope.enterprise_form.$setDirty()

    $scope.cancel = (destination) ->
      $window.location = destination

    $scope.submit = ->
      $scope.navClear()
      enterprise_form.submit()

    # Provide a callback for generating warning messages displayed before leaving the page. This is passed in
    # from a directive "nav-check" in the page - if we pass it here it will be called in the test suite,
    # and on all new uses of this contoller, and we might not want that.
    enterpriseNavCallback = ->
      if $scope.enterprise_form?.$dirty
        t('admin.unsaved_confirm_leave')

    # Register the NavigationCheck callback
    NavigationCheck.register(enterpriseNavCallback)

    $scope.performEnterpriseAction = (enterpriseActionName, warning_message_key, success_message_key) ->
      return unless confirm($scope.translation(warning_message_key))

      Enterprises[enterpriseActionName]($scope.Enterprise).then (data) ->
        $scope.Enterprise = angular.copy(data)
        $scope.$emit("enterprise:updated", $scope.Enterprise)
        StatusMessage.display("success", $scope.translation(success_message_key))
      , (response) ->
        if response.data.error?
          StatusMessage.display("failure", response.data.error)

    $scope.translation = (key) ->
      t('js.admin.enterprises.form.images.' + key)

    $scope.loadSuppliers = ->
      RequestMonitor.load $scope.suppliers = Enterprises.index(action: "visible", ams_prefix: "basic", "q[is_primary_producer_eq]": "true")
