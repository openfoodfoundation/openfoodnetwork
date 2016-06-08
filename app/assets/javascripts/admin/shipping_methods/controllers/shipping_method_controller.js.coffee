angular.module("admin.shippingMethods").controller "shippingMethodCtrl", ($scope, shippingMethod, TagRuleResource, $q) ->
  $scope.shippingMethod = shippingMethod

  $scope.findTags = (query) ->
    defer = $q.defer()
    TagRuleResource.mapByTag (data) =>
      filtered = data.filter (tag) ->
        tag.text.toLowerCase().indexOf(query.toLowerCase()) != -1
      defer.resolve filtered
    defer.promise
