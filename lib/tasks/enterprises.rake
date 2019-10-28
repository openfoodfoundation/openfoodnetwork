require 'csv'

namespace :ofn do
  desc 'deletes all orders and associated entities of an enterprise'
  task :truncate_distributor, [:distributor_id] => :environment do |_task, args|
    orders = Spree::Order.where(distributor_id: args.distributor_id)

    inventory_units = Spree::InventoryUnit.where(order_id: orders.pluck(:id))
    inventory_units.delete_all

    ProxyOrder.where(order_id: orders.pluck(:id)).destroy_all
    orders.destroy_all
  end

  namespace :dev do
    desc 'export enterprises to CSV'
    task export_enterprises: :environment do
      CSV.open('db/enterprises.csv', 'wb') do |csv|
        csv << enterprise_header
        enterprises.each do |enterprise|
          csv << enterprise_row(enterprise)
        end
      end
    end

    private

    def enterprises
      Enterprise.by_name
    end

    def enterprise_header
      ['name', 'description', 'long_description', 'is_primary_producer', 'is_distributor', 'contact_name', 'phone', 'email', 'website', 'twitter', 'abn', 'acn', 'pickup_times', 'next_collection_at', 'distributor_info', 'visible', 'facebook', 'instagram', 'linkedin', 'address1', 'address2', 'city', 'zipcode', 'state', 'country']
    end

    def enterprise_row(enterprise)
      [enterprise.name, enterprise.description, enterprise.long_description, enterprise.is_primary_producer, enterprise.is_distributor, enterprise.contact_name, enterprise.phone, enterprise.email, enterprise.website, enterprise.twitter, enterprise.abn, enterprise.acn, enterprise.pickup_times, enterprise.next_collection_at, enterprise.distributor_info, enterprise.visible, enterprise.facebook, enterprise.instagram, enterprise.linkedin, enterprise.address.address1, enterprise.address.address2, enterprise.address.city, enterprise.address.zipcode, enterprise.address.state_name, enterprise.address.country.andand.name]
    end
  end
end
