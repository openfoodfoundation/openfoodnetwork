describe 'StripeJS Service', ->
  $httpBackend = StripeJS = null
  StripeMock = { card: {} }

  beforeEach ->
    module 'Darkswarm'
    module ($provide) ->
      $provide.value "railsFlash", null
      null

    inject (_StripeJS_, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      StripeJS = _StripeJS_

  describe "requestToken", ->
    secrets = {}
    submit = null
    response = null

    beforeEach inject ($window) ->
      $window.Stripe = StripeMock

    describe "with satifactory data", ->
      beforeEach ->
        submit = jasmine.createSpy()
        response = { id: "token", card: { brand: 'MasterCard', last4: "5678", exp_month: 10, exp_year: 2099 } }
        StripeMock.card.createToken = (params, callback) => callback(200, response)

      it "saves the response data to secrets, and submits the form", ->
        StripeJS.requestToken(secrets, submit)
        expect(secrets.token).toEqual "token"
        expect(secrets.cc_type).toEqual "mastercard"
        expect(submit).toHaveBeenCalled()

    describe "with unsatifactory data", ->
      beforeEach ->
        submit = jasmine.createSpy()
        response = { id: "token", error: { message: 'There was a problem' } }
        StripeMock.card.createToken = (params, callback) => callback(400, response)

      it "doesn't submit the form, shows an error message instead", inject (Loading, RailsFlashLoader) ->
        spyOn(Loading, "clear")
        spyOn(RailsFlashLoader, "loadFlash")
        StripeJS.requestToken(secrets, submit)
        expect(submit).not.toHaveBeenCalled()
        expect(Loading.clear).toHaveBeenCalled()
        expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith({error: "Error: There was a problem"})
