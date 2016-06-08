angular.module("admin.dropdown").directive 'columnsDropdown', ->
  restrict: 'E'
  templateUrl: 'admin/columns_dropdown.html'
  controller: 'ColumnsDropdownCtrl'
  scope:
    action: '@'
