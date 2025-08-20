# frozen_string_literal: true

class TagRuleFormComponent < ViewComponent::Base
  def initialize(rule:, index:, customer_tags: "",
                 hidden_field_customer_tag_options: {})
    @rule = rule
    @index = index
    @customer_tags = customer_tags
    @hidden_field_customer_tag_options = hidden_field_customer_tag_options
  end

  attr_reader :rule, :index, :customer_tags, :hidden_field_customer_tag_options

  private

  def element_name(name)
    "enterprise[tag_rules_attributes][#{index}][#{name}]"
  end

  def rule_data # rubocop:disable Metrics/MethodLength
    case rule.type
    when "TagRule::FilterShippingMethods"
      {
        text_top: t('components.tag_rule_form.tag_rules.shipping_method_tagged_top'),
        text_bottom: t('components.tag_rule_form.tag_rules.shipping_method_tagged_bottom'),
        taggable: "shipping_method",
        visibility_field: "shipping_methods",
      }
    when "TagRule::FilterPaymentMethods"
      {
        text_top: t('components.tag_rule_form.tag_rules.payment_method_tagged_top'),
        text_bottom: t('components.tag_rule_form.tag_rules.payment_method_tagged_bottom'),
        taggable: "payment_method",
        visibility_field: "payment_methods",
      }
    when "TagRule::FilterOrderCycles"
      {
        text_top: t('components.tag_rule_form.tag_rules.order_cycle_tagged_top'),
        text_bottom: t('components.tag_rule_form.tag_rules.order_cycle_tagged_bottom'),
        taggable: "exchange",
        visibility_field: "order_cycles",
      }
    when "TagRule::FilterProducts"
      {
        text_top: t('components.tag_rule_form.tag_rules.inventory_tagged_top'),
        text_bottom: t('components.tag_rule_form.tag_rules.inventory_tagged_bottom'),
        taggable: "variant",
        visibility_field: "variants",
      }
    end
  end
end
