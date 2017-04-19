describe "UIGridReport Service", ->
  UIGridReport = aggregation = null

  beforeEach ->
    module "admin.reports"

    inject (_UIGridReport_) ->
      UIGridReport = new _UIGridReport_

  describe 'Finalizers', ->
    it '#productFinalizer', ->
      aggregation = {}
      expect(UIGridReport.productFinalizer(aggregation)).toEqual 'TOTAL'

    it '#basicFinalizer', ->
      aggregation = {value: 'big'}
      expect(UIGridReport.basicFinalizer(aggregation)).toEqual 'big'

    it '#customerFinalizer', ->
      aggregation = {order: {customer: 'customer'}}
      expect(UIGridReport.customerFinalizer(aggregation)).toEqual 'customer'

    it '#customerEmailFinalizer', ->
      aggregation = {order: {email: 'email@example.com'}}
      expect(UIGridReport.customerEmailFinalizer(aggregation)).toEqual 'email@example.com'

    it '#orderDateFinalizer', ->
      aggregation = {order: {created_at: 'any_date'}}
      expect(UIGridReport.orderDateFinalizer(aggregation)).toEqual 'any_date'

    it '#customerPhoneFinalizer', ->
      aggregation = {order: {bill_address: {phone: 'phone number'}}}
      expect(UIGridReport.customerPhoneFinalizer(aggregation)).toEqual 'phone number'

    it '#customerCityFinalizer', ->
      aggregation = {order: {bill_address: {city: 'city'}}}
      expect(UIGridReport.customerCityFinalizer(aggregation)).toEqual 'city'

    it '#paymentMethodFinalizer', ->
      aggregation = {order: {payment_method: 'payment_method'}}
      expect(UIGridReport.paymentMethodFinalizer(aggregation)).toEqual 'payment_method'

    it '#distributorFinalizer', ->
      aggregation = {order: {distributor: {name: 'distributor'}}}
      expect(UIGridReport.distributorFinalizer(aggregation)).toEqual 'distributor'

    it '#distributorAddressFinalizer', ->
      aggregation = {order: {distributor: {address1: 'address'}}}
      expect(UIGridReport.distributorAddressFinalizer(aggregation)).toEqual 'address'

    it '#distributorCityFinalizer', ->
      aggregation = {order: {distributor: {city: 'distributor city'}}}
      expect(UIGridReport.distributorCityFinalizer(aggregation)).toEqual 'distributor city'

    it '#distributorPostcodeFinalizer', ->
      aggregation = {order: {distributor: {postcode: 'postcode'}}}
      expect(UIGridReport.distributorPostcodeFinalizer(aggregation)).toEqual 'postcode'

    it '#shippingInstructionsFinalizer', ->
      aggregation = {order: {special_instructions: 'special instructions'}}
      expect(UIGridReport.shippingInstructionsFinalizer(aggregation)).toEqual 'special instructions'

    it '#orderTotalFinalizer', ->
      aggregation = {order: {total: '123'}}
      expect(UIGridReport.orderTotalFinalizer(aggregation)).toEqual '123'

    it '#orderOutstandingBalanceFinalizer', ->
      aggregation = {order: {outstanding_balance: '111'}}
      expect(UIGridReport.orderOutstandingBalanceFinalizer(aggregation)).toEqual '111'

    it '#orderPaymentTotalFinalizer', ->
      aggregation = {order: {payment_total: '222'}}
      expect(UIGridReport.orderPaymentTotalFinalizer(aggregation)).toEqual '222'

    it '#priceFinalizer', ->
      aggregation = {order: {display_total: '333'}}
      expect(UIGridReport.priceFinalizer(aggregation)).toEqual '333'

  describe 'Aggregators', ->
    describe '#sumAggregator', ->
      it 'creates value variable', ->
        aggregation = {}
        expect(UIGridReport.sumAggregator(aggregation, '1', 1)).toEqual 1

      it 'sums up value variable', ->
        aggregation = {value: 3, sum: true}
        expect(UIGridReport.sumAggregator(aggregation, '2', 2)).toEqual 5

    describe '#orderAggregator', ->
      it 'returns first row if none', ->
        aggregation = {}
        row = {entity: {order: {a: 1}}}
        expect(UIGridReport.orderAggregator(aggregation, 'fieldValue', 0, row)).toEqual {a: 1}

      it 'returns empty object if row already exists', ->
        aggregation = {order: {b: 2}}
        row = {entity: {order: {b: 2}}}

        expect(UIGridReport.orderAggregator(aggregation, 'fieldValue', 0, row)).toEqual {}

