describe "PagedFetcher service", ->
  PagedFetcher = null

  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_PagedFetcher_) ->
    PagedFetcher = _PagedFetcher_

  describe "substituting a page in the URL", ->
    it "replaces ::page:: with the given page number", ->
      expect(PagedFetcher.urlForPage("http://example.com/foo?page=::page::&per_page=20", 12)).
        toEqual "http://example.com/foo?page=12&per_page=20"
