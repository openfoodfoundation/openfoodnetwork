describe "ProductFiltersUrl service", ->
  ProductFiltersUrl = null

  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_ProductFiltersUrl_) ->
    ProductFiltersUrl = _ProductFiltersUrl_

  describe "loadFromUrl", ->
    it "should return a hash with value populated for filters existing in parameter", ->
      producerFilter = 2
      query = 'fruit'

      filters = ProductFiltersUrl.loadFromUrl(producerFilter: producerFilter, query: query)

      expect(filters.producerFilter).toBe producerFilter
      expect(filters.query).toBe query

    it "should return a hash with empty value for filters missing from parameter", ->
      filters = ProductFiltersUrl.loadFromUrl({})

      expect(filters.producerFilter).toBe ""
      expect(filters.query).toBe ""
      expect(filters.categoryFilter).toBe ""
      expect(filters.sorting).toBe ""
      expect(filters.importDateFilter).toBe ""

  describe "generate", ->
    it 'should filter given hash with productFilters', ->
      producerFilter = 2
      query = 'fruit'

      filters = ProductFiltersUrl.generate(
        producerFilter: producerFilter, query: query, otherParam: 'otherParam'
      )

      expect(filters.producerFilter).toBe producerFilter
      expect(filters.query).toBe query
      expect(filters.otherParam).toBe undefined

  describe "buildUrl", ->
    it 'should return a url adding filters to the baseUrl', inject ($httpParamSerializer) ->
      query = 'lala'
      producerFilter = 2
      categoryFilter = 5
      sorting = 'name desc'
      importDateFilter = '2020-06-08'
      filters = {
        producerFilter: producerFilter
        categoryFilter: categoryFilter
        query: query
        sorting: sorting
        importDateFilter: importDateFilter
      }
      baseUrl = "openfoodnetwork.org.au"

      url = ProductFiltersUrl.buildUrl(baseUrl, filters)

      expectedFilters = $httpParamSerializer(filters)
      expect(url).toBe("#{baseUrl}?#{expectedFilters}")

    it 'should return baseUrl if filters are empty', ->
      baseUrl = "openfoodnetwork.org.au"

      url = ProductFiltersUrl.buildUrl(baseUrl, {})
      expect(url).toBe baseUrl

