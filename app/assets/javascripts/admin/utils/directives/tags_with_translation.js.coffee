angular.module("admin.utils").directive "tagsWithTranslation", ($timeout) ->
  restrict: "E"
  templateUrl: "admin/tags_input.html"
  scope:
    object: "="
    tagsAttr: "@?"
    tagListAttr: "@?"
    findTags: "&"
  link: (scope, element, attrs) ->
    $timeout ->
      scope.tagsAttr ||= "tags"
      scope.tagListAttr ||= "tag_list"

      watchString = "object.#{scope.tagsAttr}"
      scope.$watchCollection watchString, ->
        scope.object[scope.tagListAttr] = (tag.text for tag in scope.object[scope.tagsAttr]).join(",")
