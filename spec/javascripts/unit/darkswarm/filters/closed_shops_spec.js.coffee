describe "filtering closed shops", ->
  enterprises = [{
    name: "open shop"
    active: true
    is_distributor: true
    }, {
    name: "closed shop"
    active: false
    is_distributor: true
    }, {
    name: "profile"
    active: false
    is_distributor: false
    }, {
    name: "errornous entry"
    does_not_have: "required attributes"
    }
  ]
  closedShops = null

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      closedShops = $filter('closedShops')

  it "filters closed shops, but ignores profiles and invalid entries", ->
    expect(closedShops(enterprises, false)).toEqual [enterprises[0], enterprises[2], enterprises[3]]

  it "does not filter closed shops", ->
    expect(closedShops(enterprises, true)).toEqual enterprises
