dropDownModule = angular.module("ofn.dropdown", [])

dropDownModule.directive "ofnDropDown", ->
  link: (scope, element, attrs) ->
    element.click ->
      scope.$apply ->
        if scope.expanded
          unless $(event.target).parents("div.ofn_drop_down div.menu").length > 0
            scope.expanded = false
            element.removeClass "expanded"
        else
          scope.expanded = true
          element.addClass "expanded"



dropDownModule.controller "DropDownCtrl", ->
  $scope.expanded = false
