# frozen_string_literal: true

class TagRuleFormComponent < ViewComponent::Base
  def initialize(rule:, rule_data:, index:)
    @rule = rule
    @rule_data = rule_data
    @index = index
  end

  attr_reader :rule, :index, :rule_data

  private

  def element_name(name)
    "enterprise[tag_rules_attributes][#{index}][#{name}]"
  end
end
