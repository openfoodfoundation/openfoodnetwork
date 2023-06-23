describe 'Enterprise service', ->
  $httpBackend = null
  Enterprise = null

  beforeEach ->
    module 'admin.orderCycles'
    inject ($injector, _$httpBackend_)->
      Enterprise = $injector.get('Enterprise')
      $httpBackend = _$httpBackend_
      $httpBackend.whenGET('/admin/enterprises/for_order_cycle.json').respond [
        {id: 1, name: 'One', is_primary_producer: true}
        {id: 2, name: 'Two'}
        {id: 3, name: 'Three', sells: 'any'}
        ]

  it 'loads enterprises as a hash', ->
    enterprises = Enterprise.index()
    $httpBackend.flush()
    expect(enterprises).toEqual
      1: new Enterprise.Enterprise({id: 1, name: 'One', is_primary_producer: true})
      2: new Enterprise.Enterprise({id: 2, name: 'Two'})
      3: new Enterprise.Enterprise({id: 3, name: 'Three', sells: 'any'})

  it 'reports its loadedness', ->
    expect(Enterprise.loaded).toBe(false)
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.loaded).toBe(true)

  it 'loads producers as an array', ->
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.producer_enterprises).toEqual [new Enterprise.Enterprise({id: 1, name: 'One', is_primary_producer: true})]

  it 'loads hubs as an array', ->
    Enterprise.index()
    $httpBackend.flush()
    expect(Enterprise.hub_enterprises).toEqual [new Enterprise.Enterprise({id: 3, name: 'Three', sells: 'any'})]

  it "finds supplied variants for an enterprise", ->
    spyOn(Enterprise, 'variantsOf').and.returnValue(10)
    enterprises = Enterprise.index()
    $httpBackend.flush()
    Enterprise.enterprises[1].supplied_products = [1, 2]
    expect(Enterprise.suppliedVariants(1)).toEqual [10, 10]

  describe "finding the variants of a product", ->
    it "returns the variant ids for products with variants", ->
      p =
        variants: [{id: 2}, {id: 3}]
      expect(Enterprise.variantsOf(p)).toEqual [2, 3]
