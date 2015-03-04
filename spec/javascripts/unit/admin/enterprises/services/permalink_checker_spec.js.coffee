describe "Permalink Checker service", ->
  PermalinkChecker = null
  $httpBackend = null
  beforeEach ->
    module 'admin.enterprises'

    inject ($injector, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      PermalinkChecker = $injector.get("PermalinkChecker")

  it "sends an http request to check the permalink", ->
    permalink = "this-is-a-permalink"
    $httpBackend.expectGET "/enterprises/check_permalink?permalink=#{permalink}"
    PermalinkChecker.check(permalink)