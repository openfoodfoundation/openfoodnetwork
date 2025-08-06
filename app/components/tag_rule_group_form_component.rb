# frozen_string_literal: true

class TagRuleGroupFormComponent < ViewComponent::Base
  def initialize(group:, index:, customer_rule_index:)
    @group = group
    @index = index
    @customer_rule_index = customer_rule_index
  end

  attr_reader :group, :index, :customer_rule_index

  private

  def form_id
    "tg_#{index}"
  end

  def tag_list_input_name
    "group[#{index}][preferred_customer_tags]"
  end
end
