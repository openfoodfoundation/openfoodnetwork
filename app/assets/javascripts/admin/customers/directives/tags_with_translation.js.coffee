angular.module("admin.customers").directive "tagsWithTranslation", ->
  restrict: "E"
  template: "<tags-input ng-model='object.tags'>"
  scope:
    object: "="
  link: (scope, element, attrs) ->
    scope.$watchCollection "object.tags", ->
      scope.object.tag_list = (tag.text for tag in scope.object.tags).join(",")
