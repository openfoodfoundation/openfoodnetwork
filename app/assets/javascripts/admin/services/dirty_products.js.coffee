angular.module("ofn.admin").factory "DirtyProducts", ($parse) ->
  # Temporary service to track changes in products on admin bulk product edit
  dirtyProducts = {}
  
  addDirtyProperty = (dirtyObjects, objectID, propertyName, propertyValue) ->
    dirtyObjects[objectID] = { id: objectID } if !dirtyObjects.hasOwnProperty(objectID)
    $parse(propertyName).assign(dirtyObjects[objectID], propertyValue)
    
  return {
    all: ->
      dirtyProducts

    addProductProperty: (productID, propertyName, propertyValue) ->
      addDirtyProperty dirtyProducts, productID, propertyName, propertyValue

    addMasterProperty: (productID, masterID, propertyName, propertyValue) ->
      if !dirtyProducts.hasOwnProperty(productID) or !dirtyProducts[productID].hasOwnProperty("master")
        addDirtyProperty dirtyProducts, productID, "master", { id: masterID }
      $parse(propertyName).assign(dirtyProducts[productID]["master"], propertyValue)
    
    addVariantProperty: (productID, variantID, propertyName, propertyValue) ->
      if !dirtyProducts.hasOwnProperty(productID) or !dirtyProducts[productID].hasOwnProperty("variants")
        addDirtyProperty dirtyProducts, productID, "variants", {}
      addDirtyProperty dirtyProducts[productID]["variants"], variantID, propertyName, propertyValue

    removeProductProperty: (productID, propertyName) ->
      if dirtyProducts.hasOwnProperty("#{productID}") and
        dirtyProducts["#{productID}"].hasOwnProperty("#{propertyName}") 
          delete dirtyProducts["#{productID}"]["#{propertyName}"]
          @deleteProduct productID  if Object.keys(dirtyProducts["#{productID}"]).length == 1 # ID

    removeVariantProperty: (productID, variantID, propertyName) ->
      if dirtyProducts.hasOwnProperty("#{productID}") and
        dirtyProducts["#{productID}"].hasOwnProperty("variants") and
        dirtyProducts["#{productID}"]["variants"].hasOwnProperty(variantID) and
        dirtyProducts["#{productID}"]["variants"]["#{variantID}"].hasOwnProperty("#{propertyName}")
          delete dirtyProducts["#{productID}"]["variants"]["#{variantID}"]["#{propertyName}"]
          @deleteVariant productID, variantID  if Object.keys(dirtyProducts["#{productID}"]["variants"]["#{variantID}"]).length == 1 # ID
    
    deleteProduct: (productID) ->
      delete dirtyProducts[productID]  if dirtyProducts.hasOwnProperty(productID)

    deleteVariant: (productID, variantID) ->
      if dirtyProducts.hasOwnProperty(productID) and
        dirtyProducts[productID].hasOwnProperty("variants") and
        dirtyProducts[productID].variants.hasOwnProperty(variantID)
          delete dirtyProducts["#{productID}"]["variants"]["#{variantID}"] 
          @removeProductProperty productID, "variants"  if Object.keys(dirtyProducts["#{productID}"]["variants"]).length < 1

    count: ->
      Object.keys(dirtyProducts).length

    clear: ->
      dirtyProducts = {}
  }