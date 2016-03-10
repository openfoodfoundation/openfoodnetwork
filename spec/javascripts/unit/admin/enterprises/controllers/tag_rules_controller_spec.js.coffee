describe "TagRulesCtrl", ->
  ctrl = null
  scope = null
  enterprise = null

  beforeEach ->
    module('admin.enterprises')
    enterprise =
      tag_rules: [
        { id: 1, preferred_customer_tags: "member" },
        { id: 2, preferred_customer_tags: "member" },
        { id: 3, preferred_customer_tags: "local" }
      ]

    inject ($rootScope, $controller) ->
      scope = $rootScope
      scope.Enterprise = enterprise
      ctrl = $controller 'TagRulesCtrl', {$scope: scope}

  describe "initialization", ->
    it "groups rules by preferred_customer_tags", ->
      expect(scope.groupedTagRules).toEqual {
        member: [{ id: 1, preferred_customer_tags: "member" }, { id: 2, preferred_customer_tags: "member" }],
        local: [{ id: 3, preferred_customer_tags: "local" }]
      }
