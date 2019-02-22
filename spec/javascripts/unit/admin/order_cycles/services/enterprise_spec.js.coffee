describe 'Enterprise service', ->
  $httpBackend = null
  Enterprise = null

  beforeEach ->
    module 'admin.orderCycles'
    inject ($injector, _$httpBackend_)->
      Enterprise = $injector.get('Enterprise')
      $httpBackend = _$httpBackend_
      $httpBackend.whenGET('/admin/enterprises/for_order_cycle.json').respond [
        {id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true}
        {id: 2, name: 'Two', supplied_products: [3, 4]}
        {id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'}
        ]

  it 'loads enterprises as a hash', ->
    enterprises = Enterprise.index()
    $httpBackend.flush()
    expect(enterprises).toEqual
      1: new Enterprise.Enterprise({id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true})
      2: new Enterprise.Enterprise({id: 2, name: 'Two', supplied_products: [3, 4]})
      3: new Enterprise.Enterprise({id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'})

  it 'reports its loadedness', ->
    expect(Enterprise.loaded).toBe(false)
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.loaded).toBe(true)

  it 'loads producers as an array', ->
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.producer_enterprises).toEqual [new Enterprise.Enterprise({id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true})]

  it 'loads hubs as an array', ->
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.hub_enterprises).toEqual [new Enterprise.Enterprise({id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'})]

  it 'collates all supplied products', ->
    enterprises = Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.supplied_products).toEqual [1, 2, 3, 4, 5, 6]

  it "finds supplied variants for an enterprise", ->
    spyOn(Enterprise, 'variantsOf').and.returnValue(10)
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.suppliedVariants(1)).toEqual [10, 10]

  describe "finding the variants of a product", ->
    it "returns the master for products without variants", ->
      p =
        master_id: 1
        variants: []
      expect(Enterprise.variantsOf(p)).toEqual [1]

    it "returns the variant ids for products with variants", ->
      p =
        master_id: 1
        variants: [{id: 2}, {id: 3}]
      expect(Enterprise.variantsOf(p)).toEqual [2, 3]

  it 'counts total variants supplied by an enterprise', ->
    enterprise =
      supplied_products: [
        {variants: []},
        {variants: []},
        {variants: [{}, {}, {}]}
        ]

    expect(Enterprise.totalVariants(enterprise)).toEqual(5)

  it 'returns zero when enterprise is null', ->
    expect(Enterprise.totalVariants(null)).toEqual(0)
