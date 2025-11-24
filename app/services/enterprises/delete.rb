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
        variants = enterprise.supplied_variants.with_deleted

        related_product_ids = variants.pluck(:product_id)

        # TODO: Handle related orders
        variants.joins(:line_items).pluck('spree_line_items.order_id')

        puts "==== Variants count before: #{variants.count}"
        variants.find_each do |variant|
          if skipping_condition_for(variant)
            self.skip_real_deletion = true
            next
          end

          delete_variants_related_data_for(variant)
        end
        puts "==== Variants count after: #{enterprise.reload.supplied_variants.with_deleted.count}"

        # As it is possible to have deleted products not related to any variant, but still linked
        # to an enterprise, we need to do this cleanup manually.
        remaining_product_ids =
          Spree::Product.with_deleted.where(supplier_id: enterprise.id).pluck(:id)
        delete_related_product(related_product_ids + remaining_product_ids)

        if skip_real_deletion
          puts '===== Real deletion impossible: Blocked by variants...'
        elsif !has_completed_orders?(enterprise)
          delete_enterprise(enterprise)
        else
          puts '===== Real deletion impossible: Blocked by enterprise...'
        end
      end
    end

    private

    def delete_enterprise(enterprise)
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

      enterprise.reload.destroy!
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
