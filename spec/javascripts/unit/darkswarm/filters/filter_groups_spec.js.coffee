describe "filtering Groups", ->
  filterGroups = null
  groups = [{
    name: "test"
    description: "roger"
    enterprises: [{
        name: "kittens"
      }, {
        name: "kittens"
      }]
    }, {
    name: "blankness"
    description: "in the sky"
    enterprises: [{
        name: "ponies"
      }, {
        name: "ponies"
      }]
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterGroups = $filter('groups')

  it "filters by name", ->
    expect(filterGroups(groups, "test")[0]).toBe groups[0]

  it "filters by description", ->
    expect(filterGroups(groups, "sky")[0]).toBe groups[1]

  it "filters by enterprise name", ->
    expect(filterGroups(groups, "ponies")[0]).toBe groups[1]
