# frozen_string_literal: true

module Enterprises
  class Delete
    attr_reader :enterprise
    attr_accessor :skip_real_deletion

    def initialize(enterprise:)
      @enterprise = enterprise
    end

    def call
      self.skip_real_deletion = false

      ActiveRecord::Base.transaction do
        delete_variants_for(enterprise)
        delete_variant_overrides_for(enterprise)

        if skip_real_deletion
          puts '===== Real deletion impossible: Blocked by related variants...'
        elsif !has_completed_orders?(enterprise)
          delete_enterprise_related_data_for(enterprise)

          enterprise.reload.destroy!
        else
          puts '===== Real deletion impossible: Blocked by enterprise...'
        end
      end
    end

    private

    def delete_enterprise_related_data_for(enterprise)
      # As we could force deletion when no orders were found
      ids = enterprise.distributor_shipping_methods.pluck(:id)
      DistributorShippingMethod.where(id: ids).delete_all
      ids = enterprise.distributor_payment_methods.pluck(:id)
      DistributorPaymentMethod.where(id: ids).delete_all
      # Getting cache issues on the relation locally, needed to reload it
      enterprise.enterprise_roles.delete_all
      enterprise.connected_apps.delete_all
      # We can delete them as we checked earlier that none was completed
      enterprise.distributed_orders.each(&:destroy)
      # Direct relation from enterprise to order cycle was not found
      OrderCycle.where(coordinator_id: enterprise.id).each do |order_cycle|
        # There is an control on the order cycle in case linked orders are remaining
        order_cycle.destroy!
      end
    end

    def delete_variants_for(enterprise)
      variants = enterprise.supplied_variants.with_deleted

      related_product_ids = variants.pluck(:product_id)

      # TODO: Handle related orders
      variants.joins(:line_items).pluck('spree_line_items.order_id')

      variants.find_each do |variant|
        if skipping_condition_for(variant)
          self.skip_real_deletion = true
          next
        end

        delete_variants_related_data_for(variant)
      end

      # As it is possible to have deleted products not related to any variant, but still linked
      # to an enterprise, we need to do this cleanup manually.
      remaining_product_ids =
        Spree::Product.with_deleted.where(supplier_id: enterprise.id).pluck(:id)

      delete_related_product(related_product_ids + remaining_product_ids)
    end

    def delete_variant_overrides_for(enterprise)
      # We delete the variant override only if no completed orders are linked to it.
      VariantOverride
        .unscoped
        .joins(:variant)
        .where(hub_id: enterprise.id)
        .find_each do |variant_override|
        if skipping_condition_for(variant_override.variant)
          self.skip_real_deletion = true
          next
        end

        variant_override.destroy!
      end
    end

    def delete_stock_movements_for(stock_item)
      # The table is present for history reasons. but there is no Ruby logic to call it.
      # We need to purge it manually to avoid PG constraint issues.
      sql = "DELETE FROM spree_stock_movements WHERE stock_item_id = ?"
      ActiveRecord::Base.connection.exec_delete(
        ActiveRecord::Base.sanitize_sql_array([sql, stock_item.id])
      )
    end

    def delete_variants_related_data_for(variant)
      variant.stock_items.with_deleted.find_each do |stock_item|
        delete_stock_movements_for(stock_item)

        stock_item.really_destroy!
      end

      # VariantOverride has a default scope which is breaking the deletion dependency.
      # Better to clean the table manually.
      variant.variant_overrides.unscoped.each(&:destroy)

      variant.line_items.each(&:destroy)

      variant.really_destroy!
    end

    def delete_related_product(product_ids)
      Spree::Product.with_deleted.where(id: product_ids).find_each do |product|
        # For now, let's just really delete if the product is not linked to any variants,
        # which means that the product was just linked to previously-deleted variants
        # from the current enterprise. 90% of our cases.
        if product.variants.with_deleted.exists?
          self.skip_real_deletion = true
        else
          product.really_destroy!
        end
      end
    end

    def skipping_condition_for(variant)
      orders_per_state_count = variant.line_items.joins(:order).group('spree_orders.state').count
      puts "== Related variant orders: #{orders_per_state_count}"

      # For now, we decide that we cannot delete an enterprise if at least one related variant
      # has at least one completed order linked to it.
      orders_per_state_count['complete'].to_i > 0
    end

    def has_completed_orders?(enterprise)
      orders_per_state_count = enterprise.distributed_orders.group('spree_orders.state').count
      puts "== Related enterprise orders: #{orders_per_state_count}"

      # For now, we decide that we cannot delete an enterprise if there is a completed order
      # linked to it.
      orders_per_state_count['complete'].to_i > 0
    end
  end
end
