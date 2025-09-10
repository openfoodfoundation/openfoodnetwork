# frozen_string_literal: true

class TagRuleGroupFormComponent < ViewComponent::Base
  def initialize(group:, index:, customer_rule_index:, tag_rule_types:)
    @group = group
    @index = index
    @customer_rule_index = customer_rule_index
    @tag_rule_types = tag_rule_types
  end

  attr_reader :group, :index, :customer_rule_index, :tag_rule_types

  private

  def form_id
    "tg_#{index}"
  end

  def customer_tag_rule_div_id
    "new-customer-tag-rule-#{index}"
  end

  def tag_list_input_name
    "group[#{index}][preferred_customer_tags]"
  end
end
