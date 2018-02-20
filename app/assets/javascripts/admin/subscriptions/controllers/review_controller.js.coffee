angular.module("admin.subscriptions").controller "ReviewController", ($scope, Customers, Schedules, PaymentMethods, ShippingMethods) ->
  $scope.formatAddress = (a) ->
    formatted = []
    formatted.push "#{a.firstname} #{a.lastname}"
    formatted.push a.address1
    formatted.push a.city
    formatted.push a.zipcode
    formatted.join(", ")
