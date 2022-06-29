 angular.module("admin.dropdown").directive "ofnDropDown", ($document) ->
  restrict: 'C'
  scope: true
  link: (scope, element, attrs) ->
    scope.expanded = false

    outsideClickListener = (event) ->
      unless $(event.target).is("div.ofn-drop-down##{attrs.id} div.menu") ||
        $(event.target).parents("div.ofn-drop-down##{attrs.id} div.menu").length > 0
          scope.$emit "offClick"

    element.click (event) ->
      return if event.target.closest(".ofn-drop-down").classList.contains "disabled" || event.target.classList.contains "disabled" 
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
