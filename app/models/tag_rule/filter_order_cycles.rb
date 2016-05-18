class TagRule::FilterOrderCycles < TagRule
  preference :matched_order_cycles_visibility, :string, default: "visible"
  preference :exchange_tags, :string, default: ""

  attr_accessible :preferred_matched_order_cycles_visibility, :preferred_exchange_tags

  private

  # Warning: this should only EVER be called via TagRule#apply
  def apply!
    unless preferred_matched_order_cycles_visibility == "visible"
      subject.reject!{ |oc| tags_match?(oc) }
    end
  end

  def apply_default!
    if preferred_matched_order_cycles_visibility == "visible"
      subject.reject!{ |oc| tags_match?(oc) }
    end
  end

  def tags_match?(order_cycle)
    exchange_tags = exchange_for(order_cycle).andand.tag_list || []
    preferred_tags = preferred_exchange_tags.split(",")
    ( exchange_tags & preferred_tags ).any?
  end

  def exchange_for(order_cycle)
    order_cycle.exchanges.outgoing.to_enterprise(context[:shop]).first
  end

  def subject_class_matches?
    subject.class == ActiveRecord::Relation &&
    subject.klass == OrderCycle
  end
end
