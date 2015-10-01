angular.module("admin.accounts_and_billing_settings").directive "methodSettingsFor", ->
  template: "<div ng-include='include_html'></div>"
  restrict: 'A'
  scope: {
    enterprise_id: '=methodSettingsFor'
  }
  link: (scope, element, attrs) ->
    scope.include_html = ""

    scope.$watch "enterprise_id", (newVal, oldVal)->
      if !newVal? || newVal == ""
        scope.include_html = ""
      else
        scope.include_html = "/admin/accounts_and_billing_settings/show_methods?enterprise_id=#{newVal};"
