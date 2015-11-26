angular.module("admin.indexUtils").directive "saveBar", (StatusMessage) ->
  restrict: "E"
  scope:
    save: "&"
    form: "="
  templateUrl: "admin/save_bar.html"
  link: (scope, element, attrs) ->
    scope.StatusMessage = StatusMessage
