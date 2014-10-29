module OrderCyclesHelper
  def current_order_cycle
    @current_order_cycle ||= current_order(false).andand.order_cycle
  end

  def order_cycle_permitted_enterprises
    OpenFoodNetwork::Permissions.new(spree_current_user).order_cycle_enterprises
  end

  def order_cycle_producer_enterprises
    order_cycle_permitted_enterprises.is_primary_producer.by_name
  end

  def order_cycle_coordinating_enterprises
    order_cycle_permitted_enterprises.is_distributor.by_name
  end

  def order_cycle_hub_enterprises
    enterprises = order_cycle_permitted_enterprises.is_distributor.by_name

    enterprises.map do |e|
      disabled_message = nil
      if e.shipping_methods.empty? && e.payment_methods.available.empty?
        disabled_message = 'no shipping or payment methods'
      elsif e.shipping_methods.empty?
        disabled_message = 'no shipping methods'
      elsif e.payment_methods.available.empty?
        disabled_message = 'no payment methods'
      end

      if disabled_message
        ["#{e.name} (#{disabled_message})", e.id, {disabled: true}]
      else
        [e.name, e.id]
      end
    end
  end

  def order_cycle_status_class(order_cycle)
    if order_cycle.undated?
      'undated'
    elsif order_cycle.upcoming?
      'upcoming'
    elsif order_cycle.open?
      'open'
    elsif order_cycle.closed?
      'closed'
    end
  end


  def order_cycle_options
    @order_cycles.
      with_distributor(current_distributor).
      map { |oc| [order_cycle_close_to_s(oc.orders_close_at), oc.id] }
  end

  def order_cycle_close_to_s(orders_close_at)
    "%s (%s)" % [orders_close_at.strftime("#{orders_close_at.day.ordinalize} %b"),
                 distance_of_time_in_words_to_now(orders_close_at)]
  end

  def active_order_cycle_for_distributor?(distributor)
    OrderCycle.active.with_distributor(@distributor).present?
  end

  def order_cycles_simple_view
    @order_cycles_simple_view ||= !OpenFoodNetwork::Permissions.new(spree_current_user).can_manage_complex_order_cycles?
  end

  def order_cycles_enabled?
    OpenFoodNetwork::FeatureToggle.enabled? :order_cycles
  end

  def pickup_time(order_cycle = current_order_cycle)
    order_cycle.exchanges.to_enterprises(current_distributor).outgoing.first.pickup_time
  end

end
