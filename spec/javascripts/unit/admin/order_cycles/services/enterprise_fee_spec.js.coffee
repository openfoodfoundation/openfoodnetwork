describe 'EnterpriseFee service', ->
  $httpBackend = null
  EnterpriseFee = null

  beforeEach ->
    module 'admin.orderCycles'
    inject ($injector, _$httpBackend_)->
      EnterpriseFee = $injector.get('EnterpriseFee')
      $httpBackend = _$httpBackend_
      $httpBackend.whenGET('/admin/enterprise_fees/for_order_cycle.json').respond [
        {id: 1, name: "Yayfee", enterprise_id: 1}
        {id: 2, name: "FeeTwo", enterprise_id: 2}
        ]

  it 'loads enterprise fees', ->
    enterprise_fees = EnterpriseFee.index()
    $httpBackend.flush()
    expected_fees = [
      new EnterpriseFee.EnterpriseFee({id: 1, name: "Yayfee", enterprise_id: 1})
      new EnterpriseFee.EnterpriseFee({id: 2, name: "FeeTwo", enterprise_id: 2})
      ]
    for fee, i in enterprise_fees
      expect(fee.id).toEqual(expected_fees[i].id)

  it 'reports its loadedness', ->
    expect(EnterpriseFee.loaded).toBe(false)
    EnterpriseFee.index()
    $httpBackend.flush()
    expect(EnterpriseFee.loaded).toBe(true)

  it 'returns enterprise fees for an enterprise', ->
    all_enterprise_fees = EnterpriseFee.index()
    $httpBackend.flush()
    enterprise_fees = EnterpriseFee.forEnterprise(1)
    expect(enterprise_fees).toEqual [
      new EnterpriseFee.EnterpriseFee({id: 1, name: "Yayfee", enterprise_id: 1})
      ]
