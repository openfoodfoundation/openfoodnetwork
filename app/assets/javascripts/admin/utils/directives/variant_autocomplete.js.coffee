angular.module("admin.utils").directive "variantAutocomplete", ($timeout) ->
  restrict: 'C'
  link: (scope, element, attrs) ->
    # Make variantAutocomplete do nothing because it is called
    # from core/app/assets/javascripts/admin/orders/edit.js
    $.fn.variantAutocomplete = angular.noop

    $timeout ->
      if $("#variant_autocomplete_template").length > 0
        variantTemplate = Handlebars.compile($("#variant_autocomplete_template").text())

      if Spree.routes
        element.parent().children(".options_placeholder").attr "id", element.parent().data("index")
        element.select2
          placeholder: "Select a variant"
          minimumInputLength: 3
          quietMillis: 300
          ajax:
            url: Spree.routes.variants_search
            datatype: "json"
            data: (term, page) ->
              q: term
              distributor_id: scope.distributor_id
              order_cycle_id: scope.order_cycle_id
            results: (data, page) ->
              results: data
          formatResult: (variant) ->
            if variant["images"][0] != undefined && variant["images"][0].image != undefined
              variant.image = variant.images[0].image.mini_url
            variantTemplate variant: variant
          formatSelection: (variant) ->
            element.parent().children(".options_placeholder").html variant.options_text
            variant.name
