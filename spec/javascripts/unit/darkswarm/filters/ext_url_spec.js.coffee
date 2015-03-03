describe "ensuring absolute URL", ->
  filter = null

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filter = $filter 'ext_url'

  it "returns null when no URL given", ->
    expect(filter(null, "http://")).toBeNull()

  it "returns the URL as-is for http URLs", ->
    expect(filter("http://example.com", "http://")).toEqual "http://example.com"

  it "returns the URL as-is for https URLs", ->
    expect(filter("https://example.com", "https://")).toEqual "https://example.com"

  it "returns with URL with prefix added when a relative URL is given", ->
    expect(filter("example.com", "http://")).toEqual "http://example.com"
