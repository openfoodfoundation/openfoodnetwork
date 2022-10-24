module TagRulesHelper
  TAG_RULE_OPTIONS = {
    "TagRule::FilterShippingMethods": {
      text_top: I18n.t('js.admin.tag_rules.shipping_method_tagged_top'),
      text_bottom: I18n.t('js.admin.tag_rules.shipping_method_tagged_bottom'),
      taggable: "shipping_method",
      tags_attr: "shipping_method_tags",
      tag_list_attr: "preferred_shipping_method_tags",
      input_template: "admin/tag_rules/filter_shipping_methods_input.html"
    }.freeze,
    "TagRule::FilterPaymentMethods": {
      text_top: I18n.t('js.admin.tag_rules.payment_method_tagged_top'),
      text_bottom: I18n.t('js.admin.tag_rules.payment_method_tagged_bottom'),
      taggable: "payment_method",
      tags_attr: "payment_method_tags",
      tag_list_attr: "preferred_payment_method_tags",
      input_template: "admin/tag_rules/filter_payment_methods_input.html"
    }.freeze,
    "TagRule::FilterOrderCycles": {
      text_top: I18n.t('js.admin.tag_rules.order_cycle_tagged_top'),
      text_bottom: I18n.t('js.admin.tag_rules.order_cycle_tagged_bottom'),
      taggable: "exchange",
      tags_attr: "exchange_tags",
      tag_list_attr: "preferred_exchange_tags",
      input_template: "admin/tag_rules/filter_order_cycles_input.html"
    }.freeze,
    "TagRule::FilterProducts": {
      text_top: I18n.t('js.admin.tag_rules.inventory_tagged_top'),
      text_bottom: I18n.t('js.admin.tag_rules.inventory_tagged_bottom'),
      taggable: "variant",
      tags_attr: "variant_tags",
      tag_list_attr: "preferred_variant_tags",
      input_template: "admin/tag_rules/filter_products_input.html"
    }.freeze
  }.freeze

  def tag_list_for(rule)
    case rule.type
    when "TagRule::FilterShippingMethods"
      rule.preferred_shipping_method_tags
    when "TagRule::FilterPaymentMethods"
      rule.preferred_payment_method_tags
    when "TagRule::FilterOrderCycles"
      rule.preferred_exchange_tags
    when "TagRule::FilterProducts"
      rule.preferred_variant_tags
    end
  end
end
