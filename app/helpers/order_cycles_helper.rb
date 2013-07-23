module OrderCyclesHelper
  def current_order_cycle
    @current_order_cycle ||= current_order(false).andand.order_cycle
  end

  def coordinating_enterprises
    Enterprise.is_distributor.order('name')
  end

  def order_cycle_local_remote_class(distributor, order_cycle)
    if distributor.nil? || order_cycle.nil?
      ''
    elsif order_cycle.distributors.include? distributor
      ' local'
    else
      ' remote'
    end
  end

  def distributor_options(distributors, current_distributor, order_cycle)
    options = distributors.map { |d| [d.name, d.id, {:class => order_cycle_local_remote_class(d, order_cycle).strip}] }
    options_for_select(options, current_distributor)
  end

  def order_cycles_enabled?
    OpenFoodWeb::FeatureToggle.enabled? :order_cycles
  end

end
