angular.module("admin.indexUtils").directive "saveBar", ->
  restrict: "E"
  scope:
    save: "&"
    saving: "&"
    dirty: "&"
  templateUrl: "admin/save_bar.html"
