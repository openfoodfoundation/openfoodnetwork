 angular.module("admin.dropdown").directive "linksDropdown", ($window)->
  restrict: "C"
  scope:
    links: "="
  templateUrl: "admin/links_dropdown.html"
