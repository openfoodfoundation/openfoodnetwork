angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, $window, NavigationCheck, enterprise, EnterprisePaymentMethods, EnterpriseShippingMethods, SideMenu, StatusMessage) ->
    $scope.Enterprise = enterprise
    $scope.PaymentMethods = EnterprisePaymentMethods.paymentMethods
    $scope.ShippingMethods = EnterpriseShippingMethods.shippingMethods
    $scope.navClear = NavigationCheck.clear
    $scope.pristineEmail = $scope.Enterprise.email
    $scope.menu = SideMenu
    $scope.newManager = { id: '', email: (t('add_manager')) }

    $scope.StatusMessage = StatusMessage

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
      if $scope.enterprise_form.$dirty
        t('admin.unsaved_confirm_leave')

    # Register the NavigationCheck callback
    NavigationCheck.register(enterpriseNavCallback)

    $scope.removeManager = (manager) ->
      if manager.id?
        for i, user of $scope.Enterprise.users when user.id == manager.id
          $scope.Enterprise.users.splice i, 1
        if $scope.enterprise_form?
          $scope.enterprise_form.$setDirty()

    $scope.addManager = (manager) ->
      if manager.id? and manager.email?
        manager =
          id: manager.id
          email: manager.email
        if (user for user in $scope.Enterprise.users when user.id == manager.id).length == 0
          $scope.Enterprise.users.push manager
        else
          alert ("#{manager.email}" + " " + t("is_already_manager"))
