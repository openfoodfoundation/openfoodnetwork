angular.module("admin.tagRules").directive "tagRule", ->
  restrict: "C"
  templateUrl: "admin/tag_rules/tag_rule.html"
  link: (scope, element, attrs) ->
    scope.opt =
      "TagRule::FilterShippingMethods":
         textTop: t('js.admin.tag_rules.shipping_method_tagged_top')
         textBottom: t('js.admin.tag_rules.shipping_method_tagged_bottom')
         taggable: "shipping_method"
         tagsAttr: "shipping_method_tags"
         tagListAttr: "preferred_shipping_method_tags"
         inputTemplate: "admin/tag_rules/filter_shipping_methods_input.html"
         tagListFor: (rule) ->
          rule.preferred_shipping_method_tags
      "TagRule::FilterPaymentMethods":
         textTop: t('js.admin.tag_rules.payment_method_tagged_top')
         textBottom: t('js.admin.tag_rules.payment_method_tagged_bottom')
         taggable: "payment_method"
         tagsAttr: "payment_method_tags"
         tagListAttr: "preferred_payment_method_tags"
         inputTemplate: "admin/tag_rules/filter_payment_methods_input.html"
         tagListFor: (rule) ->
          rule.preferred_payment_method_tags
      "TagRule::FilterOrderCycles":
         textTop: t('js.admin.tag_rules.order_cycle_tagged_top')
         textBottom: t('js.admin.tag_rules.order_cycle_tagged_bottom')
         taggable: "exchange"
         tagsAttr: "exchange_tags"
         tagListAttr: "preferred_exchange_tags"
         inputTemplate: "admin/tag_rules/filter_order_cycles_input.html"
         tagListFor: (rule) ->
           rule.preferred_exchange_tags
      "TagRule::FilterProducts":
         textTop: t('js.admin.tag_rules.inventory_tagged_top')
         textBottom: t('js.admin.tag_rules.inventory_tagged_bottom')
         taggable: "variant"
         tagsAttr: "variant_tags"
         tagListAttr: "preferred_variant_tags"
         inputTemplate: "admin/tag_rules/filter_products_input.html"
         tagListFor: (rule) ->
           rule.preferred_variant_tags
