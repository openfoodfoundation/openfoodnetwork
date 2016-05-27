angular.module("admin.tagRules").directive 'newTagRuleDialog', ($compile, $templateCache, DialogDefaults) ->
  restrict: 'A'
  scope:
    tagGroup: '='
    addNewRuleTo: '='
  link: (scope, element, attr) ->
    # Compile modal template
    template = $compile($templateCache.get('admin/new_tag_rule_dialog.html'))(scope)

    scope.ruleTypes = [
      # { id: "DiscountOrder", name: 'Apply a discount to orders' }
      { id: "FilterProducts", name: 'Show or Hide variants in my shopfront' }
      { id: "FilterShippingMethods", name: 'Show or Hide shipping methods at checkout' }
      { id: "FilterPaymentMethods", name: 'Show or Hide payment methods at checkout' }
      { id: "FilterOrderCycles", name: 'Show or Hide order cycles in my shopfront' }
    ]

    scope.ruleType = scope.ruleTypes[0].id

    # Set Dialog options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      template.dialog('open')

    scope.addRule = (tagGroup, ruleType) ->
      scope.addNewRuleTo(tagGroup, ruleType)
      template.dialog('close')
      return
