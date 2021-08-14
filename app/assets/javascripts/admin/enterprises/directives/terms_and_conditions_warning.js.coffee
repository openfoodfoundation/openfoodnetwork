angular.module("admin.enterprises").directive 'termsAndConditionsWarning', ($rootScope, $compile, $templateCache, DialogDefaults, $timeout) ->
  restrict: 'A'
  scope: true

  link: (scope, element, attr) ->
    # This file input click handler will hold the browser file input dialog and show a warning modal
    scope.hold_file_input_and_show_warning_modal = (event) ->
      event.preventDefault()
      scope.template = $compile($templateCache.get('admin/modals/terms_and_conditions_warning.html'))(scope)
      if scope.template.dialog
        scope.template.dialog(DialogDefaults)
        scope.template.dialog('open')
      $rootScope.$evalAsync()

    element.bind 'click', scope.hold_file_input_and_show_warning_modal

    # When the user presses continue in the warning modal, we open the browser file input dialog
    scope.continue = ->
      scope.template.dialog('close')
      $rootScope.$evalAsync()

      # unbind warning modal handler and click file input again to open the browser file input dialog
      element.unbind('click').trigger('click')
      # afterwards, bind warning modal handler again so that the warning is shown the next time
      $timeout ->
        element.bind 'click', scope.hold_file_input_and_show_warning_modal
      return

    scope.close = ->
      scope.template.dialog('close')
      $rootScope.$evalAsync()
      return
