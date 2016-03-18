angular.module("admin.utils").directive "tagsWithTranslation", ($timeout) ->
  restrict: "E"
  template: "<tags-input ng-model='object[tagsAttr]'>"
  scope:
    object: "="
    tagsAttr: "@?"
    tagListAttr: "@?"
  link: (scope, element, attrs) ->
    $timeout ->
      scope.tagsAttr ||= "tags"
      scope.tagListAttr ||= "tag_list"

      watchString = "object.#{scope.tagsAttr}"
      scope.$watchCollection watchString, ->
        scope.object[scope.tagListAttr] = (tag.text for tag in scope.object[scope.tagsAttr]).join(",")
