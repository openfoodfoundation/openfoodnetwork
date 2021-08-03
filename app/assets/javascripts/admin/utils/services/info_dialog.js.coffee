angular.module("admin.utils").factory 'InfoDialog', ($rootScope, $q, $compile, $templateCache, DialogDefaults) ->
  new class InfoDialog
    icon_classes: {
      error: 'icon-exclamation-sign'
      info: 'icon-info-sign'
    }

    open: (type, message, templateUrl='admin/info_dialog.html', options={}) ->
      deferred = $q.defer()
      scope = $rootScope.$new()
      scope.message = message
      scope.dialog_class = type
      scope.icon_class = @icon_classes[type]
      scope.options = options
      template = $compile($templateCache.get(templateUrl))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      $rootScope.$evalAsync()
      scope.close = ->
        deferred.resolve()
        template.dialog('close')
        $rootScope.$evalAsync()
        null
      deferred.promise
