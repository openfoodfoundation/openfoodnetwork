angular.module("admin.utils").directive "tagsWithTranslation", ($timeout) ->
  restrict: "E"
  template: "<tags-input ng-model='object[tagsAttr]' on-tag-added='tagAdded()' on-tag-removed='tagRemoved()'>"
  scope:
    object: "="
    tagsAttr: "@?"
    tagListAttr: "@?"
    form: '=?'
  link: (scope, element, attrs) ->
    $timeout ->
      scope.tagsAttr ||= "tags"
      scope.tagListAttr ||= "tag_list"

      compileTagList = ->
        scope.object[scope.tagListAttr] = (tag.text for tag in scope.object[scope.tagsAttr]).join(",")

      scope.tagAdded = ->
        compileTagList()

      scope.tagRemoved = ->
        # For some reason the tags input doesn't mark the form
        # as dirty when a tag is removed, which breaks the save bar
        scope.form.$setDirty(true) if typeof scope.form isnt 'undefined'
        compileTagList()
