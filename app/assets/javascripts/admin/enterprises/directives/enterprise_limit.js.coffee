angular.module('admin.enterprises').directive 'enterpriseLimit', (InfoDialog) ->
  restrict: 'A'
  scope: {
    limit_reached: '=enterpriseLimit',
    modal_message: '@modalMessage'
  }
  link: (scope, element, attr) ->
    element.bind 'click', (event)->
      if scope.limit_reached
        event.preventDefault()
        InfoDialog.open 'error', scope.modal_message
