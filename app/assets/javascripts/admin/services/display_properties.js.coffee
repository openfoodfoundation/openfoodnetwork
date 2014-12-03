angular.module("ofn.admin").factory "DisplayProperties", ->
  new class DisplayProperties
    displayProperties: {}

    showVariants: (product_id) ->
      @initProduct product_id
      @displayProperties[product_id].showVariants

    setShowVariants: (product_id, showVariants) ->
      @initProduct product_id
      @displayProperties[product_id].showVariants = showVariants

    initProduct: (product_id) ->
      @displayProperties[product_id] ||= {showVariants: false}
