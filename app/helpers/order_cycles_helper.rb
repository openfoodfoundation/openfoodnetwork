module OrderCyclesHelper
  def coordinating_enterprises
    Enterprise.is_distributor.order('name')
  end

  def order_cycle_local_remote_class(distributor, order_cycle)
    if distributor.nil?
      ''
    elsif order_cycle.distributors.include? distributor
      ' local'
    else
      ' remote'
    end
  end
end
