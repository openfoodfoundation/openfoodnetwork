describe 'CreditCards service', ->
  CreditCards = $httpBackend = RailsFlashLoader = null

  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "savedCreditCards", []
      $provide.value "railsFlash", null
      null

    inject (_CreditCards_, _$httpBackend_, _RailsFlashLoader_)->
      CreditCards = _CreditCards_
      $httpBackend = _$httpBackend_
      RailsFlashLoader = _RailsFlashLoader_

  describe "setDefault", ->
    card1 = { last4: "1234", is_default: true }
    card2 = { last4: "4321", is_default: false }
    card3 = { last4: "5555", is_default: false }
    ajax = null

    beforeEach ->
      CreditCards.saved = [card1, card2, card3]
      ajax = $httpBackend.expectPUT("/credit_cards/#{card2.id}")

    it "resets the default value on other cards to false", ->
      CreditCards.setDefault(card2)
      expect(card1.is_default).toBe false
      expect(card2.is_default).toBe true
      expect(card3.is_default).toBe false

    describe "when the update request succeeds", ->
      beforeEach ->
        spyOn(RailsFlashLoader,"loadFlash")
        ajax.respond(200)

      it "loads a success flash", ->
        CreditCards.setDefault(card2)
        $httpBackend.expectGET('/api/v0/customers.json').respond 200, []
        $httpBackend.flush()
        expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith({success: t('js.default_card_updated')})

    describe "when the update request fails", ->
      beforeEach ->
        spyOn(RailsFlashLoader,"loadFlash")
        ajax.respond(400, flash: { error: 'Some error message'})

      it "loads a error flash", ->
        CreditCards.setDefault(card2)
        $httpBackend.flush()
        expect(RailsFlashLoader.loadFlash).toHaveBeenCalledWith({error: 'Some error message'})
