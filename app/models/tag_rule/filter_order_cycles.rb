class TagRule::FilterOrderCycles < TagRule
  preference :matched_order_cycles_visibility, :string, default: "visible"
  preference :exchange_tags, :string, default: ""

  attr_accessible :preferred_matched_order_cycles_visibility, :preferred_exchange_tags

  def tags_match?(order_cycle)
    exchange_tags = exchange_for(order_cycle).andand.tag_list || []
    preferred_tags = preferred_exchange_tags.split(",")
    ( exchange_tags & preferred_tags ).any?
  end

  def reject_matched?
    preferred_matched_order_cycles_visibility != "visible"
  end

  private

  def exchange_for(order_cycle)
    order_cycle.exchanges.outgoing.to_enterprise(enterprise).first
  end
end
