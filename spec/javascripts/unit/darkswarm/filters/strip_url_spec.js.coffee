describe 'filtering urls', ->
  filter = null

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filter = $filter('stripUrl')

  it "removes http and www", ->
    expect(filter("http://www.footle.com")).toEqual "footle.com"

  it "removes https and www", ->
    expect(filter("https://www.footle.com")).toEqual "footle.com"

  it "removes just www", ->
    expect(filter("www.footle.com")).toEqual "footle.com"
