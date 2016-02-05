namespace :openfoodnetwork do
  namespace :cache do
    desc 'check the integrity of the products cache'
    task :check_products_cache_integrity => :environment do
      exchanges = Exchange.
                  outgoing.
                  joins(:order_cycle).
                  merge(OrderCycle.dated).
                  merge(OrderCycle.not_closed)

      exchanges.each do |exchange|
        Delayed::Job.enqueue ProductsCacheIntegrityCheckerJob.new(exchange.receiver, exchange.order_cycle), priority: 20
      end
    end
  end
end
