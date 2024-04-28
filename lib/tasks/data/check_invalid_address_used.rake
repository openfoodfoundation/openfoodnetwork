# frozen_string_literal: true

require 'csv'

namespace :ofn do
  namespace :data do
    # Invalid address are define by having:  address1, city, phone, or country_id set to null
    desc 'Check if any invalid address are in use'
    task check_invalid_address_used: :environment do # rubocop:disable Metrics/BlockLength
      puts "Checking for invalid address"
      invalid_addresses = Spree::Address
        .where("address1 IS NULL OR city IS NULL OR phone IS NULL OR country_id IS NULL")
        .pluck(:id)

      if invalid_addresses.empty?
        puts "No invalid address found"
        next
      end

      puts "Checking if any of #{invalid_addresses.length} invalid addresses are in use"

      # Customer :
      # - bill_address
      # - ship_address
      customer_used_address = check_bill_ship_address(Customer, invalid_addresses)
      p "Customers #{customer_used_address}"

      # Subscription :
      # - bill_address
      # - ship_address
      subscriptions_used_address = check_bill_ship_address(Subscription, invalid_addresses)
      p "Subscriptions #{subscriptions_used_address}"

      # EnterpriseGroup :
      # - enterprise_group address
      enterprise_group_used_address = check_address(EnterpriseGroup, invalid_addresses)
      p "EnterpriseGroup #{enterprise_group_used_address}"

      # User :
      # - bill_address
      # - ship_address
      users_used_address = check_bill_ship_address(Spree::User, invalid_addresses)
      p "User #{users_used_address}"

      # Order :
      # - bill_address
      # - ship_address
      orders_used_address = check_bill_ship_address(Spree::Order, invalid_addresses)
      p "Order #{orders_used_address}"

      # Shipment :
      # - address
      shipments_used_address = check_address(Spree::Shipment, invalid_addresses)
      p "Shipments #{shipments_used_address}"

      # Enterprise :
      # - address
      # - business_address
      enterprises = Enterprise
        .left_joins(:address, :business_address)
        .where(
          "address_id IN(?) OR business_address_id IN(?)", invalid_addresses, invalid_addresses
        )
      enterprise_used_address = enterprises.map do |e|
        res = []
        res << e.address_id if check_correct_address_id(e.address_id, invalid_addresses)
        res << e.business_address_id if check_correct_address_id(
          e.business_address_id, invalid_addresses
        )
        res
      end.flatten
      p "Enterprises #{enterprise_used_address}"

      address_to_be_fixed = customer_used_address.union(
        subscriptions_used_address, users_used_address, orders_used_address, shipments_used_address,
        enterprise_used_address
      )
      address_to_be_deleted = invalid_addresses - address_to_be_fixed

      puts "\n\n"
      puts "#{address_to_be_deleted.length} addresses can be deleted:"
      p address_to_be_deleted

      if address_to_be_deleted.present?
        puts "\n\n"
        puts "Run the following code to delete the addresses:"
        puts "Spree::Address.where(id: #{address_to_be_deleted}).delete_all"
      end

      puts "\n\n"
      puts "#{address_to_be_fixed.length} addresses need to be fixed:"
      p address_to_be_fixed
    end

    private

    def check_bill_ship_address(klass, addresses)
      objects = klass
        .left_joins(:bill_address, :ship_address)
        .where("bill_address_id in(?) OR ship_address_id in(?)", addresses, addresses)

      objects.map do |o|
        res = []
        res << o.ship_address_id if check_correct_address_id(o.ship_address_id, addresses)
        res << o.bill_address_id if check_correct_address_id(o.bill_address_id, addresses)
        res
      end.flatten
    end

    def check_address(klass, addresses)
      klass.joins(:address).where(address: addresses).pluck(:address_id)
    end

    def check_correct_address_id(id, missing_ids)
      !id.nil? && missing_ids.include?(id)
    end
  end
end
