angular.module("admin.utils").directive 'helpModal', ($compile, $templateCache, $window, DialogDefaults) ->
  restrict: 'C'
  scope:
    template: '@'
  link: (scope, element, attr) ->
    # Compile modal template
    template = $compile($templateCache.get(scope.template))(scope)

    # Load Dialog Options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) -> template.dialog('open')

    scope.close = ->
      template.dialog('close')
      return
