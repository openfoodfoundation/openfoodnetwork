angular.module("admin.indexUtils").factory 'KeyValueMapStore', (localStorageService)->
  new class KeyValueMapStore
    localStorageKey: ''
    storableKeys: []

    constructor: ->
      localStorageService.setStorageType("sessionStorage")

    getStoredKeyValueMap: ->
      localStorageService.get(@localStorageKey) || {}

    setStoredValues: (source) ->
      keyValueMap = {}
      for key in @storableKeys
        keyValueMap[key] = source[key]
      localStorageService.set(@localStorageKey, keyValueMap)

    restoreValues: (target) ->
      storedKeyValueMap = @getStoredKeyValueMap()
      
      return false if _.isEmpty(storedKeyValueMap)  
      
      for k,v of storedKeyValueMap
       target[k] = v

      return true

    clearKeyValueMap: () ->
      localStorageService.remove(@localStorageKey)
