# Returns a (paginatable) AR object for the products or variants in stock for a given shop and OC.
# The stock-checking includes on_demand and stock level overrides from variant_overrides.

class OrderCycleDistributedProducts
  def initialize(distributor, order_cycle, customer)
    @distributor = distributor
    @order_cycle = order_cycle
    @customer = customer
  end

  def products_relation
    Spree::Product.where(id: stocked_products)
  end

  def variants_relation
    order_cycle.
      variants_distributed_by(distributor).
      merge(stocked_variants_and_overrides)
  end

  private

  attr_reader :distributor, :order_cycle, :customer

  def stocked_products
    order_cycle.
      variants_distributed_by(distributor).
      merge(stocked_variants_and_overrides).
      select("DISTINCT spree_variants.product_id")
  end

  def stocked_variants_and_overrides
    stocked_variants = Spree::Variant.
      joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.variant_id = spree_variants.id
            AND variant_overrides.hub_id = #{distributor.id}").
      joins(:stock_items).
      where(query_stock_with_overrides)

    if distributor_rules.any?
      stocked_variants = apply_tag_rules(stocked_variants)
    end

    stocked_variants
  end

  def apply_tag_rules(stocked_variants)
    stocked_variants.where(query_with_tag_rules)
  end

  def distributor_rules
    @distributor_rules ||= TagRule::FilterProducts.prioritised.for(distributor)
  end

  def customer_tag_list
    customer.andand.tag_list || []
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

  def overrides_to_hide
    @overrides_to_hide = VariantOverride.where(hub_id: distributor.id).
      tagged_with(default_rule_tags + hide_rule_tags, any: true).
      pluck(:id)
  end

  def overrides_to_show
    @overrides_to_show = VariantOverride.where(hub_id: distributor.id).
      tagged_with(show_rule_tags, any: true).
      pluck(:id)
  end

  def customer_applicable_rules
    # Rules which apply specifically to the current customer
    @customer_applicable_rules ||= non_default_rules.select{ |rule| customer_tagged?(rule) }
  end

  def default_rules
    # These rules hide a variant_override with tag X
    distributor_rules.select(&:is_default?)
  end

  def non_default_rules
    # These rules show or hide a variant_override with tag X for customer with tag Y
    distributor_rules.reject(&:is_default?)
  end

  def hide_rules
    @hide_rules ||= customer_applicable_rules.select{ |rule| rule.preferred_matched_variants_visibility == 'hidden'}
  end

  def show_rules
    customer_applicable_rules - hide_rules
  end

  def customer_tagged?(rule)
    customer_tag_list.include? rule.preferred_customer_tags
  end

  def query_stock_with_overrides
    "( #{variant_not_overriden} AND ( #{variant_on_demand} OR #{variant_in_stock} ) )
      OR ( #{variant_overriden} AND ( #{override_on_demand} OR #{override_in_stock} ) )
      OR ( #{variant_overriden} AND ( #{override_on_demand_null} AND #{variant_on_demand} ) )
      OR ( #{variant_overriden} AND ( #{override_on_demand_null}
                                      AND #{variant_not_on_demand} AND #{variant_in_stock} ) )"
  end

  def query_with_tag_rules
    "#{variant_not_overriden} OR ( #{variant_overriden}
                                   AND ( #{override_not_hidden_by_rule}
                                   OR #{override_shown_by_rule} ) )"
  end

  def override_not_hidden_by_rule
    return "FALSE" unless overrides_to_hide.any?
    "variant_overrides.id NOT IN (#{overrides_to_hide.join(',')})"
  end

  def override_shown_by_rule
    return "FALSE" unless overrides_to_show.any?
    "variant_overrides.id IN (#{overrides_to_show.join(',')})"
  end

  def variant_not_overriden
    "variant_overrides.id IS NULL"
  end

  def variant_overriden
    "variant_overrides.id IS NOT NULL"
  end

  def variant_in_stock
    "spree_stock_items.count_on_hand > 0"
  end

  def variant_on_demand
    "spree_stock_items.backorderable IS TRUE"
  end

  def variant_not_on_demand
    "spree_stock_items.backorderable IS FALSE"
  end

  def override_on_demand
    "variant_overrides.on_demand IS TRUE"
  end

  def override_in_stock
    "variant_overrides.count_on_hand > 0"
  end

  def override_on_demand_null
    "variant_overrides.on_demand IS NULL"
  end
end
