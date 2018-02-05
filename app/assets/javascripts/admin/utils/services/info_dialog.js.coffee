angular.module("admin.utils").factory 'InfoDialog', ($rootScope, $compile, $injector, $templateCache, DialogDefaults) ->
  new class InfoDialog
    open: (type, message, templateUrl='admin/info_dialog.html', options={}) ->
      scope = $rootScope.$new()
      scope.message = message
      scope.dialog_class = type
      scope.options = options
      template = $compile($templateCache.get(templateUrl))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      scope.close = ->
        template.dialog('close')
        null
