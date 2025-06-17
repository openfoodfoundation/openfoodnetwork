angular.module("admin.tagRules").directive 'newTagRuleDialog', ($rootScope, $compile, $templateCache, DialogDefaults, ruleTypes) ->
  restrict: 'A'
  scope:
    tagGroup: '='
    addNewRuleTo: '='
  link: (scope, element, attr) ->
    # Compile modal template
    template = $compile($templateCache.get('admin/new_tag_rule_dialog.html'))(scope)

    scope.ruleTypes = ruleTypes

    scope.ruleType = scope.ruleTypes[0].id

    # Set Dialog options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      template.dialog('open')
      $rootScope.$evalAsync()

    scope.addRule = (tagGroup, ruleType) ->
      scope.addNewRuleTo(tagGroup, ruleType)
      template.dialog('close')
      $rootScope.$evalAsync()
      return
