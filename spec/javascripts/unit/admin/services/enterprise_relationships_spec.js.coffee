describe "enterprise relationships", ->
  EnterpriseRelationships = null
  enterprise_relationships = []

  beforeEach ->
    module "ofn.admin"
    module ($provide) ->
      $provide.value "enterprise_relationships", enterprise_relationships
      null

  beforeEach inject (_EnterpriseRelationships_) ->
    EnterpriseRelationships = _EnterpriseRelationships_

  it "presents permission names", ->
    expect(EnterpriseRelationships.permission_presentation("add_to_order_cycle")).toEqual "can add to order cycle"
    expect(EnterpriseRelationships.permission_presentation("manage_products")).toEqual "can manage the products of"
