require 'open_food_network/products_cache_integrity_checker'

namespace :openfoodnetwork do
  namespace :cache do
    desc 'check the integrity of the products cache'
    task :check_products_integrity => :environment do
      Exchange.cachable.each do |exchange|
        Delayed::Job.enqueue ProductsCacheIntegrityCheckerJob.new(exchange.receiver_id, exchange.order_cycle_id), priority: 20
      end
    end


    desc 'warm the products cache'
    task :warm_products => :environment do
      Exchange.cachable.each do |exchange|
        Delayed::Job.enqueue RefreshProductsCacheJob.new(exchange.receiver_id, exchange.order_cycle_id), priority: 10
      end
    end
  end
end
