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
    expect(EnterpriseRelationships.permission_presentation("add_products_to_order_cycle")).toEqual "can add products to order cycle from"
    expect(EnterpriseRelationships.permission_presentation("manage_products")).toEqual "can manage the products of"
