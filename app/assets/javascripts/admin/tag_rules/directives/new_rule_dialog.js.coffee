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
      { id: "FilterProducts", name: t('js.tag_rules.show_hide_variants') }
      { id: "FilterShippingMethods", name: t('js.tag_rules.show_hide_shipping') }
      { id: "FilterPaymentMethods", name: t('js.tag_rules.show_hide_payment') }
      { id: "FilterOrderCycles", name: t('js.tag_rules.show_hide_order_cycles') }
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
