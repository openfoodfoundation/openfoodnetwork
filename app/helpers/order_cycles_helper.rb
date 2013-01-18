module OrderCyclesHelper
  def coordinating_enterprises
    Enterprise.is_distributor.order('name')
  end
end
