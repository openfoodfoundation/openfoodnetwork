describe "TagRulesCtrl", ->
  ctrl = null
  scope = null
  enterprise = null

  beforeEach ->
    module('admin.tagRules')
    enterprise =
      id: 45
      default_tag_group: { tags: "", rules: [{ id: 7, preferred_customer_tags: "trusted" }] }
      tag_groups: [
        { tags: "member", rules: [{ id: 1, preferred_customer_tags: "member" }, { id: 2, preferred_customer_tags: "member" }] },
        { tags: "volunteer", rules: [{ id: 3, preferred_customer_tags: "local" }] }
      ]

    inject ($rootScope, $controller) ->
      scope = $rootScope
      scope.enterprise_form = jasmine.createSpyObj('enterprise_form', ['$setDirty'])
      ctrl = $controller 'TagRulesCtrl', {$scope: scope, enterprise: enterprise}

  describe "tagGroup start indices", ->
    it "updates on initialization", ->
      expect(scope.tagGroups[0].startIndex).toEqual 1
      expect(scope.tagGroups[1].startIndex).toEqual 3

  describe "adding a new tag group", ->
    beforeEach ->
      scope.addNewRuleTo(scope.tagGroups[0], "FilterOrderCycles")

    it "adds a new rule of the specified type to the rules array for the tagGroup", ->
      expect(scope.tagGroups[0].rules.length).toEqual 3
      expect(scope.tagGroups[0].rules[2].type).toEqual "TagRule::FilterOrderCycles"

    it "updates tagGroup start indices", ->
      expect(scope.tagGroups[0].startIndex).toEqual 1
      expect(scope.tagGroups[1].startIndex).toEqual 4

  describe "deleting a tag group", ->
    describe "where the rule is not in the rule list for the tagGroup", ->
      beforeEach ->
        scope.deleteTagRule(scope.tagGroups[0],scope.tagGroups[1].rules[0])

      it "does not remove any rules", ->
        expect(scope.tagGroups[0].rules.length).toEqual 2
        expect(scope.tagGroups[1].rules.length).toEqual 1

    describe "with an id", ->
      rule = null

      beforeEach inject ($httpBackend) ->
        rule = scope.tagGroups[0].rules[0]
        spyOn(window, "confirm").and.returnValue(true)
        $httpBackend.expectDELETE('/admin/enterprises/45/tag_rules/1.json').respond(status: 204)
        scope.deleteTagRule(scope.tagGroups[0], rule)
        $httpBackend.flush()

      it "removes the specified rule from the rules list", ->
        expect(scope.tagGroups[0].rules.length).toEqual 1
        expect(scope.tagGroups[1].rules.length).toEqual 1
        expect(scope.tagGroups[0].rules.indexOf(rule)).toEqual -1

      it "updates tagGroup start indices", ->
        expect(scope.tagGroups[0].startIndex).toEqual 1
        expect(scope.tagGroups[1].startIndex).toEqual 2

    describe "without an id", ->
      rule = null

      beforeEach inject ($httpBackend) ->
        rule = scope.tagGroups[0].rules[0]
        rule.id = null
        scope.deleteTagRule(scope.tagGroups[0], rule)

      it "removes the specified rule from the rules list", ->
        expect(scope.tagGroups[0].rules.length).toEqual 1
        expect(scope.tagGroups[1].rules.length).toEqual 1
        expect(scope.tagGroups[0].rules.indexOf(rule)).toEqual -1

      it "updates tagGroup start indices", ->
        expect(scope.tagGroups[0].startIndex).toEqual 1
        expect(scope.tagGroups[1].startIndex).toEqual 2
