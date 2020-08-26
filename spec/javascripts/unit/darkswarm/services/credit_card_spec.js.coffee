describe 'CreditCard service', ->
  CreditCard = null
  CreditCards = null
  $http = null
  Loading = null
  RailsFlashLoader = null

  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "savedCreditCards", []
      $provide.value "railsFlash", null
      null

    inject (_CreditCard_, _CreditCards_, _$httpBackend_, _Loading_, _RailsFlashLoader_)->
      CreditCard = _CreditCard_
      CreditCards = _CreditCards_
      $http = _$httpBackend_
      Loading = _Loading_
      RailsFlashLoader = _RailsFlashLoader_

    CreditCard.secrets =
      card:
        exp_month: "12"
        exp_year: "2030"
        last4: "1234"
      cc_type: 'mastercard'
      token: "token123"

  describe "submit", ->
    it "adds a credit card", ->
      $http.expectPUT("/credit_cards/new_from_token").respond(200, {})
      spyOn(CreditCards, "add")

      CreditCard.submit()
      $http.flush()

      expect(CreditCards.add).toHaveBeenCalled()

    it "reports errors", ->
      $http.expectPUT("/credit_cards/new_from_token").respond(500, {})
      spyOn(Loading, "clear")
      spyOn(RailsFlashLoader, "loadFlash")

      CreditCard.submit()
      $http.flush()

      expect(Loading.clear).toHaveBeenCalled()
      expect(RailsFlashLoader.loadFlash).toHaveBeenCalled()

  describe "process_params", ->
    it "uses cc_type, rather than fetching the brand from the card", ->
      # This is important for processing the card with activemerchant
      process_params = CreditCard.process_params()
      expect(process_params['exp_month']).toEqual "12"
      expect(process_params['exp_year']).toEqual "2030"
      expect(process_params['last4']).toEqual "1234"
      expect(process_params['token']).toEqual "token123"
      expect(process_params['cc_type']).toEqual "mastercard"
