angular.module("admin.utils").factory 'InfoDialog', ($rootScope, $compile, $injector, $templateCache, DialogDefaults) ->
  new class InfoDialog
    open: (type, message) ->
      scope = $rootScope.$new()
      scope.message = message
      scope.dialog_class = type
      template = $compile($templateCache.get('admin/info_dialog.html'))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      scope.close = ->
        template.dialog('close')
        null
