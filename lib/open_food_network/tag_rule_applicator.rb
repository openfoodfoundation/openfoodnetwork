# frozen_string_literal: true

module OpenFoodNetwork
  class TagRuleApplicator
    attr_reader :enterprise, :rule_class, :customer_tags

    def initialize(enterprise, rule_type, customer_tags = [])
      raise "Enterprise cannot be nil" if enterprise.nil?
      raise "Rule Type cannot be nil" if rule_type.nil?

      @enterprise = enterprise
      @rule_class = "TagRule::#{rule_type}".constantize
      @customer_tags = customer_tags || []
    end

    def filter(subject)
      subject.to_a.reject do |element|
        if rule_class.respond_to?(:tagged_children_for)
          children = rule_class.tagged_children_for(element)
          children.reject! { |child| reject?(child) }
          children.empty?
        else
          reject?(element)
        end
      end
    end

    def rules
      return @rules unless @rules.nil?

      @rules = rule_class.prioritised.for(enterprise)
    end

    private

    def reject?(element)
      customer_rules.each do |rule|
        return rule.reject_matched? if rule.tags_match?(element)
      end

      default_rules.each do |rule|
        return rule.reject_matched? if rule.tags_match?(element)
      end

      false
    end

    def customer_rules
      return @customer_matched_rules unless @customer_matched_rules.nil?

      @customer_matched_rules = rules.select{ |rule| customer_tags_match?(rule) }
    end

    def default_rules
      return @default_rules unless @default_rules.nil?

      @default_rules = rules.select(&:is_default?)
    end

    def customer_tags_match?(rule)
      preferred_tags = rule.preferred_customer_tags.split(",")
      (customer_tags & preferred_tags).any?
    end
  end
end
