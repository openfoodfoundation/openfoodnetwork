# frozen_string_literal: true

class TagRuleFormComponent < ViewComponent::Base
  def initialize(rule:, rule_data:, index:, customer_tags: "",
                 hidden_field_customer_tag_options: {})
    @rule = rule
    @rule_data = rule_data
    @index = index
    @customer_tags = customer_tags
    @hidden_field_customer_tag_options = hidden_field_customer_tag_options
  end

  attr_reader :rule, :index, :rule_data, :customer_tags, :hidden_field_customer_tag_options

  private

  def element_name(name)
    "enterprise[tag_rules_attributes][#{index}][#{name}]"
  end
end
