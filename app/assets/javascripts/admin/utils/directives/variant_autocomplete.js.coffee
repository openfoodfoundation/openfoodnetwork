angular.module("admin.utils").directive "variantAutocomplete", ($timeout) ->
  restrict: 'C'
  link: (scope, element, attrs) ->
    $timeout ->
      if $("#variant_autocomplete_template").length > 0
        variantTemplate = Handlebars.compile($("#variant_autocomplete_template").text())

      if Spree.routes
        element.parent().children(".options_placeholder").attr "id", element.parent().data("index")
        element.select2
          placeholder: t('admin.orders.select_variant')
          minimumInputLength: 3
          formatInputTooShort: ->
            t('admin.select2.minimal_search_length', count: 3)
          formatSearching: ->
            t('admin.select2.searching')
          formatNoMatches: ->
            t('admin.select2.no_matches')
          ajax:
            url: Spree.routes.variants_search
            datatype: "json"
            quietMillis: 500 # debounce
            data: (term, page) ->
              q: term
              distributor_id: scope.distributor_id
              order_cycle_id: scope.order_cycle_id
              eligible_for_subscriptions: scope.eligible_for_subscriptions
              include_out_of_stock: scope.include_out_of_stock
            results: (data, page) ->
              window.variants = data # this is how spree auto complete JS code picks up variants
              results: data
          formatResult: (variant) ->
            variantTemplate variant: variant
          formatSelection: (variant) ->
            element.parent().children(".options_placeholder").html variant.options_text
            variant.name
        element.on "select2-opening", ->
          scope.include_out_of_stock = if $('#include_out_of_stock').is(':checked') then "1" else ""
