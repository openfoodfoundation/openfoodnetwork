angular.module("admin.utils").directive "alertRow", ->
  restrict: "E"
  replace: true
  scope:
    message: '@'
    buttonText: '@?'
    buttonAction: '&?'
    close: "&?"
  transclude: true
  templateUrl: "admin/alert_row.html"
  link: (scope, element, attrs) ->
    scope.dismiss = ->
      scope.close() if scope.close?
      element.hide()
      return false
