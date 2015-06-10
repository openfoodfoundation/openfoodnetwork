 angular.module("admin.dropdown").directive "ofnDropDown", ($document) ->
  link: (scope, element, attrs) ->
    outsideClickListener = (event) ->
      unless $(event.target).is("div.ofn_drop_down##{attrs.id} div.menu") ||
        $(event.target).parents("div.ofn_drop_down##{attrs.id} div.menu").length > 0
          scope.$emit "offClick"

    element.click (event) ->
      if !scope.expanded
        event.stopPropagation()
        scope.deregistrationCallback = scope.$on "offClick", ->
          $document.off "click", outsideClickListener
          scope.$apply ->
            scope.expanded = false
            element.removeClass "expanded"
            scope.deregistrationCallback()
        $document.on "click", outsideClickListener
        scope.$apply ->
          scope.expanded = true
          element.addClass "expanded"
