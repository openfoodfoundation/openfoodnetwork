angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, $http, $window, NavigationCheck, enterprise, Enterprises, SideMenu, StatusMessage, RequestMonitor) ->
    $scope.Enterprise = enterprise
    $scope.Enterprises = Enterprises
    $scope.navClear = NavigationCheck.clear
    $scope.menu = SideMenu
    $scope.newManager = { id: null, email: (t('add_manager')) }
    $scope.StatusMessage = StatusMessage
    $scope.RequestMonitor = RequestMonitor

    $scope.$watch 'enterprise_form.$dirty', (newValue) ->
      StatusMessage.display 'notice', t('admin.unsaved_changes') if newValue

    $scope.$watch 'newManager', (newValue) ->
      $scope.addManager($scope.newManager) if newValue

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

    $scope.removeManager = (manager) ->
      if manager.id?
        if manager.id == $scope.Enterprise.owner.id or manager.id == parseInt($scope.receivesNotifications)
          return
        for i, user of $scope.Enterprise.users when user.id == manager.id
          $scope.Enterprise.users.splice i, 1
          $scope.enterprise_form?.$setDirty()

    $scope.addManager = (manager) ->
      if manager.id? and angular.isNumber(manager.id) and manager.email?
        manager =
          id: manager.id
          email: manager.email
          confirmed: manager.confirmed
        if (user for user in $scope.Enterprise.users when user.id == manager.id).length == 0
          $scope.Enterprise.users.unshift(manager)
          $scope.enterprise_form?.$setDirty()
        else
          alert ("#{manager.email}" + " " + t("is_already_manager"))

    $scope.removeLogo = ->
      $scope.performEnterpriseAction("removeLogo", "immediate_logo_removal_warning", "removed_logo_successfully")

    $scope.removePromoImage = ->
      $scope.performEnterpriseAction("removePromoImage", "immediate_promo_image_removal_warning", "removed_promo_image_successfully")

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
