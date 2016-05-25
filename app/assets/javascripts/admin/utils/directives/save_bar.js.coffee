angular.module("admin.utils").directive "saveBar", (StatusMessage) ->
  restrict: "E"
  transclude: true
  scope:
    dirty: "="
    persist: "=?"
  templateUrl: "admin/save_bar.html"
  link: (scope, element, attrs) ->
    scope.StatusMessage = StatusMessage
