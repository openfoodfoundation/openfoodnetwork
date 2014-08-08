describe "Taxons service", ->
  Taxons = taxons = $httpBackend = $resource = null

  beforeEach ->
    module "ofn.admin"
    module ($provide)->
      $provide.value "taxons", [{id: "1", name: "t1"}, {id: "2", name: "t2"}, {id: "12", name: "t12"}, {id: "31", name: "t31"}]
      null

  beforeEach inject (_Taxons_, _$resource_, _$httpBackend_) ->
    Taxons = _Taxons_
    $resource = _$resource_
    $httpBackend = _$httpBackend_

  describe "findByID", ->
    it "returns the taxon with exactly matching id, ignoring ids which do not exactly match", ->
      result = Taxons.findByID("1")
      expect(result).toEqual {id: "1", name: "t1"}

  describe "findByIDs", ->
    it "returns taxons with exactly matching ids", ->
      result = Taxons.findByIDs("1,2")
      expect(result).toEqual [{id: "1", name: "t1"}, {id: "2", name: "t2"}]

    it "ignores ids which do not exactly match", ->
      result = Taxons.findByIDs("1,3")
      expect(result).toEqual [{id: "1", name: "t1"}]

  describe "findByTerm", ->
    it "returns taxons which match partially", ->
      result = Taxons.findByTerm("t1")
      expect(result).toEqual [{id: "1", name: "t1"}, {id: "12", name: "t12"}]