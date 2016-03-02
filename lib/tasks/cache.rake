namespace :openfoodnetwork do
  namespace :cache do
    desc 'check the integrity of the products cache'
    task :check_products_integrity => :environment do
      active_exchanges.each do |exchange|
        Delayed::Job.enqueue ProductsCacheIntegrityCheckerJob.new(exchange.receiver_id, exchange.order_cycle_id), priority: 20
      end
    end


    desc 'warm the products cache'
    task :warm_products => :environment do
      active_exchanges.each do |exchange|
        Delayed::Job.enqueue RefreshProductsCacheJob.new(exchange.receiver_id, exchange.order_cycle_id), priority: 10
      end
    end


    private

    def active_exchanges
      ProductsCacheIntegrityChecker.active_exchanges
    end
  end
end
