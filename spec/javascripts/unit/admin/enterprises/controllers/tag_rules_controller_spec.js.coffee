describe "TagRulesCtrl", ->
  ctrl = null
  scope = null
  enterprise = null

  beforeEach ->
    module('admin.enterprises')
    enterprise =
      tag_groups: [
        { tags: "member", rules: [{ id: 1, preferred_customer_tags: "member" }, { id: 2, preferred_customer_tags: "member" }] },
        { tags: "volunteer", rules: [{ id: 3, preferred_customer_tags: "local" }] }
      ]

    inject ($rootScope, $controller) ->
      scope = $rootScope
      scope.Enterprise = enterprise
      ctrl = $controller 'TagRulesCtrl', {$scope: scope}

  describe "tagGroup start indices", ->
    it "updates on initialization", ->
      expect(scope.tagGroups[0].startIndex).toEqual 0
      expect(scope.tagGroups[1].startIndex).toEqual 2

    it "updates when tags are added to a tagGroup", ->
      scope.addNewRuleTo(scope.tagGroups[0])
      expect(scope.tagGroups[0].startIndex).toEqual 0
      expect(scope.tagGroups[1].startIndex).toEqual 3
