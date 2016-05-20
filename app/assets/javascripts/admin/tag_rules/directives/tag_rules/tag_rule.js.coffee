angular.module("admin.tagRules").directive "tagRule", ->
  restrict: "C"
  templateUrl: "admin/tag_rules/tag_rule.html"
  link: (scope, element, attrs) ->
    scope.opt =
      "TagRule::FilterShippingMethods":
         textTop: "Shipping methods tagged"
         textBottom: "are:"
         taggable: "shipping_method"
         tagsAttr: "shipping_method_tags"
         tagListAttr: "preferred_shipping_method_tags"
         inputTemplate: "admin/tag_rules/filter_shipping_methods_input.html"
         tagListFor: (rule) ->
          rule.preferred_shipping_method_tags
      "TagRule::FilterPaymentMethods":
         textTop: "Payment methods tagged"
         textBottom: "are:"
         taggable: "payment_method"
         tagsAttr: "payment_method_tags"
         tagListAttr: "preferred_payment_method_tags"
         inputTemplate: "admin/tag_rules/filter_payment_methods_input.html"
         tagListFor: (rule) ->
          rule.preferred_payment_method_tags
      "TagRule::FilterOrderCycles":
         textTop: "Order Cycles tagged"
         textBottom: "are:"
         taggable: "exchange"
         tagsAttr: "exchange_tags"
         tagListAttr: "preferred_exchange_tags"
         inputTemplate: "admin/tag_rules/filter_order_cycles_input.html"
         tagListFor: (rule) ->
           rule.preferred_exchange_tags
      "TagRule::FilterProducts":
         textTop: "Inventory variants tagged"
         textBottom: "are:"
         taggable: "variant"
         tagsAttr: "variant_tags"
         tagListAttr: "preferred_variant_tags"
         inputTemplate: "admin/tag_rules/filter_products_input.html"
         tagListFor: (rule) ->
           rule.preferred_variant_tags
