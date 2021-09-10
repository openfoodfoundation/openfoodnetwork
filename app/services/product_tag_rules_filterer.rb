# frozen_string_literal: true

# Takes a Spree::Variant AR object and filters results based on applicable tag rules.
# Tag rules exists in the context of enterprise, customer, and variant_overrides,
# and are applied to variant_overrides only. Returns a Spree::Variant AR object.

class ProductTagRulesFilterer
  def initialize(distributor, customer, variants_relation)
    @distributor = distributor
    @customer = customer
    @variants_relation = variants_relation
  end

  def call
    return variants_relation unless distributor_rules.any?

    filter(variants_relation)
  end

  private

  attr_accessor :distributor, :customer, :variants_relation

  def distributor_rules
    @distributor_rules ||= TagRule::FilterProducts.prioritised.for(distributor).all
  end

  def filter(variants_relation)
    return variants_relation unless overrides_to_hide.any?

    variants_relation.where(query_with_tag_rules)
  end

  def query_with_tag_rules
    "#{variant_not_overriden} OR ( #{variant_overriden}
                                   AND ( #{override_not_hidden_by_rule}
                                   OR #{override_shown_by_rule} ) )"
  end

  def variant_not_overriden
    "variant_overrides.id IS NULL"
  end

  def variant_overriden
    "variant_overrides.id IS NOT NULL"
  end

  def override_not_hidden_by_rule
    return "FALSE" unless overrides_to_hide.any?

    "variant_overrides.id NOT IN (#{overrides_to_hide.join(',')})"
  end

  def override_shown_by_rule
    return "FALSE" unless overrides_to_show.any?

    "variant_overrides.id IN (#{overrides_to_show.join(',')})"
  end

  def overrides_to_hide
    @overrides_to_hide ||= VariantOverride.where(hub_id: distributor.id).
      tagged_with(default_rule_tags + hide_rule_tags, any: true).
      pluck(:id)
  end

  def overrides_to_show
    @overrides_to_show ||= VariantOverride.where(hub_id: distributor.id).
      tagged_with(show_rule_tags, any: true).
      pluck(:id)
  end

  def default_rule_tags
    default_rules.map(&:preferred_variant_tags)
  end

  def hide_rule_tags
    hide_rules.map(&:preferred_variant_tags)
  end

  def show_rule_tags
    show_rules.map(&:preferred_variant_tags)
  end

  def default_rules
    # These rules hide a variant_override with tag X and apply to all customers
    distributor_rules.select(&:is_default?)
  end

  def non_default_rules
    # These rules show or hide a variant_override with tag X for customer with tag Y
    distributor_rules.reject(&:is_default?)
  end

  def customer_applicable_rules
    # Rules which apply specifically to the current customer
    @customer_applicable_rules ||= non_default_rules.select{ |rule| customer_tagged?(rule) }
  end

  def hide_rules
    @hide_rules ||= customer_applicable_rules.
      select{ |rule| rule.preferred_matched_variants_visibility == 'hidden' }
  end

  def show_rules
    customer_applicable_rules - hide_rules
  end

  def customer_tagged?(rule)
    customer_tag_list.include? rule.preferred_customer_tags
  end

  def customer_tag_list
    customer&.tag_list || []
  end
end
