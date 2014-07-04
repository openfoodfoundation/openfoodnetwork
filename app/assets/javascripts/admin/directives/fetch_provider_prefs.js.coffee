angular.module("ofn.admin").directive "ofnFetchProviderPrefs", ($http) ->
  link: (scope, element, attrs) ->
    element.on "change blur", ->
      scope.$apply ->
        scope.include_html = "/admin/payment_methods/#{attrs.ofnFetchProviderPrefs}/show_provider_preferences?provider_type=#{element.val()}"