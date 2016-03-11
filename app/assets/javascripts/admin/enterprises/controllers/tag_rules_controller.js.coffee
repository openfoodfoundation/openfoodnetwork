angular.module("admin.enterprises").controller "TagRulesCtrl", ($scope) ->
  $scope.tagGroups = $scope.Enterprise.tag_groups

  updateRuleCounts = ->
    index = 0
    for tagGroup in $scope.tagGroups
      tagGroup.startIndex = index
      index = index + tagGroup.rules.length

  updateRuleCounts()

  $scope.updateTagsRulesFor = (tagGroup) ->
    for tagRule in tagGroup.rules
      tagRule.preferred_customer_tags = (tag.text for tag in tagGroup.tags).join(",")

  $scope.addNewRuleTo = (tagGroup) ->
    tagGroup.rules.push
      id: null
      preferred_customer_tags: (tag.text for tag in tagGroup.tags).join(",")
      type: "TagRule::DiscountOrder"
      calculator:
        preferred_flat_percent: 0
    updateRuleCounts()

  $scope.addNewTag = ->
    $scope.tagGroups.push { tags: [], rules: [] }
