angular.module("admin.utils").directive "textangularStrip", () ->
  restrict: 'CA'
  link: (scope, element, attrs) ->
    scope.stripFormatting = ($html) ->
      element = document.createElement("div")
      element.innerHTML = String($html)
      allTags = element.getElementsByTagName("*")
      for child in allTags
        child.removeAttribute("style")
        child.removeAttribute("class")
      return element.innerHTML
