# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc "Adding relationships based on recent order cycles"
    task create_order_cycle_relationships: :environment do
      input = request_months

      # For each order cycle which was modified within the past 3 months
      OrderCycle.where('updated_at > ?', Date.current - input.months).each do |order_cycle|
        # Cycle through the incoming exchanges
        order_cycle.exchanges.incoming.each do |exchange|
          next if exchange.sender == exchange.receiver

          # Ensure that an enterprise relationship from the producer to the coordinator exists
          relationship = EnterpriseRelationship.where(parent_id: exchange.sender_id,
                                                      child_id: exchange.receiver_id).first
          if relationship.blank?
            puts "CREATING: #{exchange.sender.name} TO #{exchange.receiver.name}"
            relationship = EnterpriseRelationship.create!(parent_id: exchange.sender_id,
                                                          child_id: exchange.receiver_id)
          end
          # And that P-OC is granted
          unless relationship.has_permission?(:add_to_order_cycle)
            puts "PERMITTING: #{exchange.sender.name} TO #{exchange.receiver.name}"
            relationship.permissions.create!(name: :add_to_order_cycle)
          end
        end

        # Cycle through the outgoing exchanges
        order_cycle.exchanges.outgoing.each do |exchange|
          unless exchange.sender == exchange.receiver
            # Enure that an enterprise relationship from the hub to the coordinator exists
            relationship = EnterpriseRelationship.where(parent_id: exchange.receiver_id,
                                                        child_id: exchange.sender_id).first
            if relationship.blank?
              puts "CREATING: #{exchange.receiver.name} TO #{exchange.sender.name}"
              relationship = EnterpriseRelationship.create!(parent_id: exchange.receiver_id,
                                                            child_id: exchange.sender_id)
            end
            # And that P-OC is granted
            unless relationship.has_permission?(:add_to_order_cycle)
              puts "PERMITTING: #{exchange.receiver.name} TO #{exchange.sender.name}"
              relationship.permissions.create!(name: :add_to_order_cycle)
            end
          end

          # For each variant in the exchange
          products = Spree::Product.joins(:variants).where(
            'spree_variants.id IN (?)', exchange.variants
          ).pluck(:id).uniq
          producers = Enterprise.joins(:supplied_products).where("spree_products.id IN (?)",
                                                                 products).distinct
          producers.each do |producer|
            next if producer == exchange.receiver

            # Ensure that an enterprise relationship from the producer to the hub exists
            relationship = EnterpriseRelationship.where(parent_id: producer.id,
                                                        child_id: exchange.receiver_id).first
            if relationship.blank?
              puts "CREATING: #{producer.name} TO #{exchange.receiver.name}"
              relationship = EnterpriseRelationship.create!(parent_id: producer.id,
                                                            child_id: exchange.receiver_id)
            end
            # And that P-OC is granted
            unless relationship.has_permission?(:add_to_order_cycle)
              puts "PERMITTING: #{producer.name} TO #{exchange.receiver.name}"
              relationship.permissions.create!(name: :add_to_order_cycle)
            end
          end
        end
      end
    end

    def request_months
      # Ask how many months back we want to search for
      puts "This task will search order cycle edited within (n) months of today's date.\n" \
           "Please enter a value for (n), or hit ENTER to use the default of three (3) months."
      input = check_default(STDIN.gets.chomp)

      while !is_integer?(input)
        puts "'#{input}' is not an integer. Please enter an integer."
        input = check_default(STDIN.gets.chomp)
      end

      Integer(input)
    end

    def check_default(input)
      if input.blank?
        puts "Using default value of three (3) months."
        3
      else
        input
      end
    end

    def is_integer?(value)
      return true if Integer(value)
    rescue StandardError
      false
    end
  end
end
