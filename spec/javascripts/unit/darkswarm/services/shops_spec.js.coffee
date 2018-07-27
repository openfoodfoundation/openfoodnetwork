describe 'Shops', ->
  describe "initialisation", ->
    Shops = null
    shops = ['some shop']

    beforeEach ->
      module 'Darkswarm'

    describe "when the injector does not have a value for 'shops'", ->
      beforeEach ->
        inject (_Shops_) ->
          Shops = _Shops_

      it "does nothing, leaves @all empty", ->
        expect(Shops.all).toEqual []

    describe "when the injector has a value for 'shops'", ->
      beforeEach ->
        module ($provide) ->
          $provide.value 'shops', shops
          null

        inject (_Shops_) ->
          Shops = _Shops_

      it "loads injected shops array into @all", ->
        expect(Shops.all).toEqual shops
