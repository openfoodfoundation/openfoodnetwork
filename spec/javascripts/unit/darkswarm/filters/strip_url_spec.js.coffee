describe 'filtering urls', ->
  filter = null

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filter = $filter('stripUrl')

  it "removes http", ->
    expect(filter("http://footle.com")).toEqual "footle.com"

  it "removes https", ->
    expect(filter("https://www.footle.com")).toEqual "www.footle.com"
