# frozen_string_literal: true

require 'csv'

namespace :ofn do
  # Note this task is still rather naive and only covers the simple case where
  # an enterprise was created but never used and thus, does not have any
  # associated entities like orders.
  desc 'remove the specified enterprise'
  task :remove_enterprise, [:enterprise_id] => :environment do |_task, args|
    enterprise = Enterprise.find(args.enterprise_id)
    enterprise.destroy
  end

  namespace :enterprises do
    desc "Activate connected app type for ALL enterprises"
    task :activate_connected_app_type, [:type] => :environment do |_task, args|
      Enterprise.find_each do |enterprise|
        next if enterprise.connected_apps.public_send(args.type.underscore).exists?

        "ConnectedApps::#{args.type.camelize}".constantize.new(enterprise:).connect({})
        puts "Enterprise #{enterprise.id} connected."
      end
    end
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
      ['name', 'description', 'long_description', 'is_primary_producer', 'is_distributor',
       'contact_name', 'phone', 'email', 'website', 'twitter', 'abn', 'acn',
       'visible', 'facebook', 'instagram', 'linkedin',
       'address1', 'address2', 'city', 'zipcode', 'state', 'country']
    end

    def enterprise_row(enterprise)
      [enterprise.name, enterprise.description, enterprise.long_description,
       enterprise.is_primary_producer, enterprise.is_distributor, enterprise.contact_name,
       enterprise.phone, enterprise.email, enterprise.website, enterprise.twitter, enterprise.abn,
       enterprise.acn,
       enterprise.visible, enterprise.facebook, enterprise.instagram,
       enterprise.linkedin, enterprise.address.address1, enterprise.address.address2,
       enterprise.address.city, enterprise.address.zipcode, enterprise.address.state_name,
       enterprise.address.country&.name]
    end
  end
end
