namespace :ofn do
  desc 'destroys the specified order cycle'
  task :remove_order_cycle, [:order_cycle_id] => :environment do |_task, args|
    remove_order_cycle(args.order_cycle_id)
  end

  desc 'destroys all order cycles of the specified coordinator'
  task :remove_coordinated_order_cycles, [:coordinator_id] => :environment do |_task, args|
    order_cycles = OrderCycle.where(coordinator_id: args.coordinator_id)
    order_cycles.each { |order_cycle| remove_order_cycle(order_cycle.id) }
  end

  private

  def remove_order_cycle(order_cycle_id)
    CoordinatorFee.where(order_cycle_id: order_cycle_id).delete_all
    OrderCycle.find(order_cycle_id).destroy
  end
end
