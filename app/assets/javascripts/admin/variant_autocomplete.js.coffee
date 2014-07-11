$(document).ready ->
  if $("#variant_autocomplete_template").length > 0
    window.variantTemplate = Handlebars.compile($("#variant_autocomplete_template").text())

formatVariantResult = (variant) ->
  if variant["images"][0] != undefined && variant["images"][0].image != undefined
    variant.image = variant.images[0].image.mini_url
  variantTemplate variant: variant

$.fn.variantAutocomplete = ->
  if Spree.routes
    @parent().children(".options_placeholder").attr "id", @parent().data("index")
    @select2
      placeholder: "Select a variant"
      minimumInputLength: 3
      ajax:
        url: Spree.routes.variants_search
        datatype: "json"
        data: (term, page) ->
          q: term
          distributor_id: $("#order_distributor_id").val()
          order_cycle_id: $("#order_order_cycle_id").val()

        results: (data, page) ->
          results: data

      formatResult: formatVariantResult
      formatSelection: (variant) ->
        $(@element).parent().children(".options_placeholder").html variant.options_text
        variant.name
