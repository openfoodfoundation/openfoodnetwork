describe 'CreditCard service', ->
  CreditCard = null

  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "savedCreditCards", []
      $provide.value "railsFlash", null
      null

    inject (_CreditCard_)->
      CreditCard = _CreditCard_

  describe "process_params", ->
    beforeEach ->
      CreditCard.secrets =
        card:
          exp_month: "12"
          exp_year: "2030"
          last4: "1234"
        cc_type: 'mastercard'
        token: "token123"

    it "uses cc_type, rather than fetching the brand from the card", ->
      # This is important for processing the card with activemerchant
      process_params = CreditCard.process_params()
      expect(process_params['exp_month']).toEqual "12"
      expect(process_params['exp_year']).toEqual "2030"
      expect(process_params['last4']).toEqual "1234"
      expect(process_params['token']).toEqual "token123"
      expect(process_params['cc_type']).toEqual "mastercard"
