describe "Test KeyValueMapStore service", ->

  KeyValueMapStore = null
  
  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_KeyValueMapStore_) ->
    KeyValueMapStore = _KeyValueMapStore_

  it "set and restore filters", ->
    KeyValueMapStore.localStorageKey = 'localStorageKey'
    KeyValueMapStore.storableKeys = ["a", "b", "c"]
    source =
      a: "1",
      b: "2",
      d: "4"
    KeyValueMapStore.setStoredValues(source)
    source = {}
    restored = KeyValueMapStore.restoreValues(source)
    expect(restored).toEqual true
    expect(source).toEqual {a: '1', b: '2'}

  it "clear filters", ->
    KeyValueMapStore.storageKey = 'localStorageKey'
    KeyValueMapStore.storableFilters = ["a", "b", "c"]
    source =
      a: "1",
      b: "2",
      d: "4"
    KeyValueMapStore.setStoredValues(source)
    KeyValueMapStore.clearKeyValueMap()
    source = {}
    restored = KeyValueMapStore.restoreValues(source)
    expect(restored).toEqual false
    expect(source).toEqual {}


