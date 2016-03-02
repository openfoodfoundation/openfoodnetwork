require 'open_food_network/products_cache_integrity_checker'

ProductsCacheIntegrityCheckerJob = Struct.new(:distributor_id, :order_cycle_id) do
  def perform
    unless checker.ok?
      Bugsnag.notify RuntimeError.new("Products JSON differs from cached version for distributor: #{distributor_id}, order cycle: #{order_cycle_id}"), diff: checker.diff.to_s(:text)
    end
  end


  private

  def checker
    OpenFoodNetwork::ProductsCacheIntegrityChecker.new(distributor, order_cycle)
  end

  def distributor
    Enterprise.find distributor_id
  end

  def order_cycle
    OrderCycle.find order_cycle_id
  end
end
