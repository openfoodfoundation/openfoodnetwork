angular.module("admin.utils").directive "alertRow", ->
  restrict: "E"
  replace: true
  scope:
    message: '@'
    buttonText: '@?'
    buttonAction: '&?'
    dismissed: '=?'
    close: "&?"
  transclude: true
  templateUrl: "admin/alert_row.html"
  link: (scope, element, attrs) ->
    scope.dismissed = false

    scope.dismiss = ->
      scope.dismissed = true
      scope.close() if scope.close?
      return false
