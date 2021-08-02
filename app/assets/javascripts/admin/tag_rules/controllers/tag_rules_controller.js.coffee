angular.module("admin.tagRules").controller "TagRulesCtrl", ($scope, $http, $filter, enterprise) ->
  $scope.tagGroups = enterprise.tag_groups
  $scope.defaultTagGroup = enterprise.default_tag_group

  $scope.visibilityOptions = [ { id: "visible", name: t('js.tag_rules.visible')  }, { id: "hidden", name: t('js.tag_rules.not_visible') } ]

  $scope.updateRuleCounts = ->
    index = $scope.defaultTagGroup.rules.length
    for tagGroup in $filter('orderBy')($scope.tagGroups, 'position')
      tagGroup.startIndex = index
      index = index + tagGroup.rules.length

  $scope.updateRuleCounts()

  $scope.updateTagsRulesFor = (tagGroup) ->
    for tagRule in tagGroup.rules
      tagRule.preferred_customer_tags = (tag.text for tag in tagGroup.tags).join(",")

  $scope.addNewRuleTo = (tagGroup, ruleType) ->
    newRule =
        id: null
        is_default: tagGroup == $scope.defaultTagGroup
        preferred_customer_tags: (tag.text for tag in tagGroup.tags).join(",")
        type: "TagRule::#{ruleType}"
    switch ruleType
      when "FilterShippingMethods"
        newRule.peferred_shipping_method_tags = []
        newRule.preferred_matched_shipping_methods_visibility = "visible"
      when "FilterPaymentMethods"
        newRule.peferred_payment_method_tags = []
        newRule.preferred_matched_payment_methods_visibility = "visible"
      when "FilterProducts"
        newRule.peferred_variant_tags = []
        newRule.preferred_matched_variants_visibility = "visible"
      when "FilterOrderCycles"
        newRule.peferred_exchange_tags = []
        newRule.preferred_matched_order_cycles_visibility = "visible"
    tagGroup.rules.push(newRule)
    $scope.updateRuleCounts()

  $scope.addNewTag = ->
    $scope.tagGroups.push { tags: [], rules: [], position: $scope.tagGroups.length + 1 }

  $scope.deleteTagRule = (tagGroup, tagRule) ->
    index = tagGroup.rules.indexOf(tagRule)
    return unless index >= 0
    if tagRule.id is null
      tagGroup.rules.splice(index, 1)
      $scope.updateRuleCounts()
    else
      if confirm("Are you sure?")
        $http
          method: "DELETE"
          url: "/admin/enterprises/#{enterprise.id}/tag_rules/#{tagRule.id}.json"
        .then ->
          tagGroup.rules.splice(index, 1)
          $scope.updateRuleCounts()
          $scope.enterprise_form.$setDirty()
