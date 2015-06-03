angular.module("ofn.admin").factory "DisplayProperties", ->
  new class DisplayProperties
    displayProperties: {}

    showVariants: (product_id) ->
      @productProperties(product_id).showVariants

    setShowVariants: (product_id, showVariants) ->
      @productProperties(product_id).showVariants = showVariants

    productProperties: (product_id) ->
      @displayProperties[product_id] ||= {showVariants: false}
