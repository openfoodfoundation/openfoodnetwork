angular.module("admin.utils").directive "tagsWithTranslation", ($timeout) ->
  restrict: "E"
  templateUrl: "admin/tags_input.html"
  scope:
    object: "="
    form: "="
    tagsAttr: "@?"
    tagListAttr: "@?"
    findTags: "&"
    form: '=?'
    onTagAdded: "&"
    onTagRemoved: "&"
    max: "="
  link: (scope, element, attrs) ->
    scope.findTags = undefined unless attrs.hasOwnProperty("findTags")
    scope.limitReached = false

    compileTagList = ->
      scope.limitReached = scope.object[scope.tagsAttr].length >= scope.max if scope.max != undefined
      scope.object[scope.tagListAttr] = (tag.text for tag in scope.object[scope.tagsAttr]).join(",")

    scope.$watch "object", (newObject) -> 
      scope.object = newObject
      init()

    $timeout ->
      init()
    
    init = ->
      return unless scope.object
      # Initialize properties if necessary
      scope.tagsAttr ||= "tags"
      scope.tagListAttr ||= "tag_list"
      scope.object[scope.tagsAttr] ||= []
      compileTagList()

      scope.tagAdded = (tag)->
        tag.text = tag.text.toLowerCase()
        scope.onTagAdded()
        compileTagList()

      scope.tagRemoved = ->
        # For some reason the tags input doesn't mark the form
        # as dirty when a tag is removed, which breaks the save bar
        scope.form.$setDirty(true) if typeof scope.form isnt 'undefined'
        scope.onTagRemoved()
        compileTagList()
