angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, NavigationCheck, Enterprise, EnterprisePaymentMethods, EnterpriseShippingMethods, SideMenu) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.PaymentMethods = EnterprisePaymentMethods.paymentMethods
    $scope.ShippingMethods = EnterpriseShippingMethods.shippingMethods
    $scope.navClear = NavigationCheck.clear
    $scope.pristineEmail = $scope.Enterprise.email
    $scope.menu = SideMenu

    # Provide a callback for generating warning messages displayed before leaving the page. This is passed in
    # from a directive "nav-check" in the page - if we pass it here it will be called in the test suite,
    # and on all new uses of this contoller, and we might not want that .
    enterpriseNavCallback = ->
      if $scope.Enterprise.$dirty
        "Your changes to the enterprise are not saved yet."

    # Register the NavigationCheck callback
    NavigationCheck.register(enterpriseNavCallback)
