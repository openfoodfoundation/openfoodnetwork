angular.module("admin.utils").directive "saveBar", (StatusMessage) ->
  restrict: "E"
  scope:
    save: "&"
    form: "="
    buttons: "="
  templateUrl: "admin/save_bar.html"
  link: (scope, element, attrs) ->
    scope.StatusMessage = StatusMessage
