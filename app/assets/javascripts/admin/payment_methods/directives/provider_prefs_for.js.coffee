angular.module("admin.paymentMethods").directive "providerPrefsFor", ($http) ->
  link: (scope, element, attrs) ->
    element.on "change blur load", ->
      scope.$apply ->
        scope.include_html = "/admin/payment_methods/show_provider_preferences?" +
          "provider_type=#{element.val()};" +
          "pm_id=#{attrs.providerPrefsFor};"
