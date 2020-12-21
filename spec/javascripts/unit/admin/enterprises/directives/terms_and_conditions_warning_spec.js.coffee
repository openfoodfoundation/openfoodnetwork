describe "termsAndConditionsWarning", ->
  element = null
  templatecache = null

  beforeEach ->
    module('admin.enterprises')

    inject ($rootScope, $compile, $templateCache) ->
      templatecache = $templateCache
      el = angular.element("<input terms-and-conditions-warning=\"true\"></input>")
      element = $compile(el)($rootScope)
      $rootScope.$digest()

  describe "terms and conditions warning", ->
    it "should load template", ->
      spyOn(templatecache, 'get')
      element.triggerHandler('click');
      expect(templatecache.get).toHaveBeenCalledWith('admin/modals/terms_and_conditions_warning.html')
