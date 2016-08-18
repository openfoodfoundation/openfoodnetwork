Darkswarm.factory 'Variants', ->
  new class Variants
    variants: {}

    clear: ->
      @variants = {}

    register: (variant)->
      @variants[variant.id] ||= @extend variant

    extend: (variant)->
      variant.extended_name = @extendedVariantName(variant)
      variant.base_price_percentage = Math.round(variant.price / variant.price_with_fees * 100)
      variant.line_item ||= @lineItemFor(variant) # line_item may have been initialised in Cart#constructor
      variant.line_item.total_price = variant.price_with_fees * variant.line_item.quantity
      variant

    extendedVariantName: (variant) =>
      if variant.product_name == variant.name_to_display
        variant.product_name
      else
        name =  "#{variant.product_name} - #{variant.name_to_display}"
        name += " (#{variant.options_text})" if variant.options_text
        name

    lineItemFor: (variant) ->
      variant: variant
      quantity: null
      max_quantity: null
