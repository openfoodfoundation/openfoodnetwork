angular.module("admin.utils").factory 'ConfirmDialog', ($rootScope, $q, $compile, $templateCache, DialogDefaults) ->
  new class ConfirmDialog
    open: (type, message, options) ->
      deferred = $q.defer()
      scope = $rootScope.$new()
      scope.message = message
      scope.dialog_class = type
      scope.confirmText = options?.confirm || t('ok')
      scope.cancelText = options?.cancel || t('cancel')
      template = $compile($templateCache.get('admin/confirm_dialog.html'))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      scope.confirm = ->
        deferred.resolve()
        template.dialog('close')
        null
      scope.close = ->
        deferred.reject()
        template.dialog('close')
        null
      deferred.promise
