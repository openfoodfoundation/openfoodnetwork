angular.module('Darkswarm').factory 'Variants', ->
  new class Variants
    variants: {}

    clear: ->
      @variants = {}

    register: (variant)->
      @variants[variant.id] ||= @extend variant

    extend: (variant)->
      variant.extended_name = @extendedVariantName(variant)
      variant.line_item ||= @lineItemFor(variant) # line_item may have been initialised in Cart#constructor
      variant.line_item.total_price = variant.price_with_fees * variant.line_item.quantity
      variant

    extendedVariantName: (variant) =>
      if variant.product_name == variant.name_to_display
        name = variant.product_name
      else
        name =  "#{variant.product_name} - #{variant.name_to_display}"
      name

    lineItemFor: (variant) ->
      variant: variant
      quantity: 0
      max_quantity: 0
