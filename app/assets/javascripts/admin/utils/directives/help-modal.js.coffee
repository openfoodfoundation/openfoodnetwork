angular.module("admin.utils").directive 'helpModal', ($rootScope, $compile, $templateCache, $window, DialogDefaults) ->
  restrict: 'C'
  scope:
    template: '@'
  link: (scope, element, attr) ->
    # Compile modal template
    template = $compile($templateCache.get(scope.template))(scope)

    # Load Dialog Options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      template.dialog('open')
      $rootScope.$evalAsync()

    scope.close = ->
      template.dialog('close')
      $rootScope.$evalAsync()
      return
