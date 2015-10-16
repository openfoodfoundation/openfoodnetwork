describe "Permalink Checker service", ->
  PermalinkChecker = null
  $httpBackend = null
  permalink = "this-is-a-permalink"
  permalink_too_long = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  permalink_invalid_chars = "<html>"

  beforeEach ->
    module 'admin.enterprises'

    inject ($injector, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      PermalinkChecker = $injector.get("PermalinkChecker")

  it "responds to available permalinks", ->
    $httpBackend.expectGET("/enterprises/check_permalink?permalink=#{permalink}").respond permalink
    PermalinkChecker.check(permalink).then (data) ->
      expect(data.permalink).toEqual permalink
      expect(data.available).toEqual "Available"
    $httpBackend.flush()

  it "responds to unavailable permalinks", ->
    $httpBackend.expectGET("/enterprises/check_permalink?permalink=#{permalink}").respond 409, permalink
    PermalinkChecker.check(permalink).then (data) ->
      expect(data.permalink).toEqual permalink
      expect(data.available).toEqual "Unavailable"
    $httpBackend.flush()

  describe "invalid data", ->
    it "errors for permalinks that are too long", ->
      $httpBackend.expectGET("/enterprises/check_permalink?permalink=#{permalink}").respond permalink_too_long
      PermalinkChecker.check(permalink).then (data) ->
        expect(data.permalink).toEqual permalink
        expect(data.available).toEqual "Error"
      $httpBackend.flush()

    it "errors for permalinks that contain invalid characters", ->
      $httpBackend.expectGET("/enterprises/check_permalink?permalink=#{permalink}").respond permalink_invalid_chars
      PermalinkChecker.check(permalink).then (data) ->
        expect(data.permalink).toEqual permalink
        expect(data.available).toEqual "Error"
      $httpBackend.flush()
