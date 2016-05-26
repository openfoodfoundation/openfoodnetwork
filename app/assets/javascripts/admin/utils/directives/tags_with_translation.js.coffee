angular.module("admin.utils").directive "tagsWithTranslation", ($timeout) ->
  restrict: "E"
  templateUrl: "admin/tags_input.html"
  scope:
    object: "="
    tagsAttr: "@?"
    tagListAttr: "@?"
    findTags: "&"
    form: '=?'
  link: (scope, element, attrs) ->
    scope.findTags = undefined unless attrs.hasOwnProperty("findTags")

    compileTagList = ->
      scope.object[scope.tagListAttr] = (tag.text for tag in scope.object[scope.tagsAttr]).join(",")

    $timeout ->
      # Initialize properties if necessary
      scope.tagsAttr ||= "tags"
      scope.tagListAttr ||= "tag_list"
      scope.object[scope.tagsAttr] ||= []
      compileTagList()

      scope.tagAdded = ->
        compileTagList()

      scope.tagRemoved = ->
        # For some reason the tags input doesn't mark the form
        # as dirty when a tag is removed, which breaks the save bar
        scope.form.$setDirty(true) if typeof scope.form isnt 'undefined'
        compileTagList()
