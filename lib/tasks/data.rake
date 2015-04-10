namespace :openfoodnetwork do
  namespace :data do
    desc "Adding relationships based on recent order cycles"
    task :create_order_cycle_relationships => :environment do
      # For each order cycle which was modified within the past 3 months
      OrderCycle.where('updated_at > ?', Date.today - 3.months).each do |order_cycle|
        # Cycle through the incoming exchanges
        order_cycle.exchanges.incoming.each do |exchange|
          # Ensure that an enterprise relationship from the producer to the coordinator exists
          relationship = EnterpriseRelationship.where(parent_id: exchange.sender_id, child_id: exchange.receiver_id).first
          unless relationship.present?
            puts "CREATING: #{exchange.sender.name} TO #{exchange.receiver.name}"
            relationship = EnterpriseRelationship.create!(parent_id: exchange.sender_id, child_id: exchange.receiver_id)
          end
          # And that P-OC is granted
          unless relationship.has_permission?(:add_to_order_cycle)
            puts "PERMITTING: #{exchange.sender.name} TO #{exchange.receiver.name}"
            relationship.permissions.create!(name: :add_to_order_cycle)
          end
        end

        # Cycle through the outgoing exchanges
        order_cycle.exchanges.outgoing.each do |exchange|
          # Enure that an enterprise relationship from the hub to the coordinator exists
          relationship = EnterpriseRelationship.where(parent_id: exchange.receiver_id, child_id: exchange.sender_id).first
          unless relationship.present?
            puts "CREATING: #{exchange.receiver.name} TO #{exchange.sender.name}"
            relationship = EnterpriseRelationship.create!(parent_id: exchange.receiver_id, child_id: exchange.sender_id)
          end
          # And that P-OC is granted
          unless relationship.has_permission?(:add_to_order_cycle)
            puts "PERMITTING: #{exchange.receiver.name} TO #{exchange.sender.name}"
            relationship.permissions.create!(name: :add_to_order_cycle)
          end

          # For each variant in the exchange
          products = Spree::Product.joins(:variants_including_master).where('spree_variants.id IN (?)', exchange.variants).pluck(:id).uniq
          producers = Enterprise.joins(:supplied_products).where("spree_products.id IN (?)", products).uniq
          producers.each do |producer|
            # Ensure that an enterprise relationship from the producer to the hub exists
            relationship = EnterpriseRelationship.where(parent_id: producer.id, child_id: exchange.receiver_id).first
            unless relationship.present?
              puts "CREATING: #{producer.name} TO #{exchange.receiver.name}"
              relationship = EnterpriseRelationship.create!(parent_id: producer.id, child_id: exchange.receiver_id)
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
  end
end
