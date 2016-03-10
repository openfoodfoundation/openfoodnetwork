angular.module("admin.enterprises").controller "TagRulesCtrl", ($scope) ->
  $scope.groupedTagRules = $scope.Enterprise.tag_rules.reduce (groupedTagRules, rule) ->
    key = rule.preferred_customer_tags
    groupedTagRules[key] ||= []
    groupedTagRules[key].push rule
    groupedTagRules
  , {}
